import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/ui/screens/loans/loans_screen.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_screen.dart';
import 'package:ark_flutter/src/ui/screens/core/walletscreen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/bottom_nav_gradient.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class BottomNav extends StatefulWidget {
  final String aspId;

  const BottomNav({super.key, required this.aspId});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  // Keys for child screens
  final GlobalKey<WalletScreenState> _walletKey =
      GlobalKey<WalletScreenState>();
  final GlobalKey<SwapScreenState> _swapKey = GlobalKey<SwapScreenState>();
  final GlobalKey<LoansScreenState> _loansKey = GlobalKey<LoansScreenState>();

  @override
  void initState() {
    super.initState();
    _screens = [
      WalletScreen(key: _walletKey, aspId: widget.aspId),
      SwapScreen(key: _swapKey),
      LoansScreen(key: _loansKey, aspId: widget.aspId),
    ];

    // Initialize payment monitoring after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPaymentMonitoring();
    });
  }

  void _initPaymentMonitoring() {
    final paymentService = context.read<PaymentMonitoringService>();

    paymentService.initialize(
      context: context,
      onWalletRefresh: () {
        logger.i("Payment received - refreshing wallet");
        _walletKey.currentState?.fetchWalletData();
      },
    );

    // Set up callback for switching to wallet tab (used by swap screen)
    paymentService.onSwitchToWalletTab = () {
      logger.i("Switching to wallet tab");
      _onItemTapped(0);
      _walletKey.currentState?.fetchWalletData();
    };
  }

  void _onItemTapped(int index) {
    // Close any open bottom sheets/dialogs before switching tabs
    Navigator.of(context).popUntil((route) => route is! PopupRoute);

    // Dismiss keyboard and unfocus all screens when switching tabs
    FocusScope.of(context).unfocus();
    _swapKey.currentState?.unfocusAll();
    _loansKey.currentState?.unfocusAll();
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData icon, bool isLight) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: double.infinity,
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? (isLight ? Colors.black : Colors.white)
                  : (isLight ? Colors.grey.shade600 : Colors.grey.shade400),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: isKeyboardVisible
          ? const SizedBox.shrink()
          : Container(
              color: isLight ? Colors.grey.shade200 : Colors.black,
              padding: const EdgeInsets.only(
                left: AppTheme.cardPadding,
                right: AppTheme.cardPadding,
                bottom: AppTheme.cardPadding * 1,
              ),
              child: GlassContainer(
                height: AppTheme.cardPadding * 2.75,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, FontAwesomeIcons.wallet, isLight),
                    _buildNavItem(
                        1, FontAwesomeIcons.arrowRightArrowLeft, isLight),
                    _buildNavItem(
                        2, FontAwesomeIcons.handHoldingDollar, isLight),
                  ],
                ),
              ),
            ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavGradient(),
          ),
        ],
      ),
    );
  }
}
