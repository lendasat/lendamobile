import 'package:ark_flutter/src/ui/screens/loans_screen.dart';
import 'package:ark_flutter/src/ui/screens/swap_screen.dart';
import 'package:ark_flutter/src/ui/screens/walletscreen.dart';
import 'package:ark_flutter/src/ui/widgets/utility/bottom_nav_gradient.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNav extends StatefulWidget {
  final String aspId;

  const BottomNav({super.key, required this.aspId});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WalletScreen(aspId: widget.aspId),
      const SwapScreen(),
      const LoansScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem(int index, IconData icon, bool isLight) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Icon(
          icon,
          size: 24,
          color: isSelected
              ? (isLight ? Colors.black : Colors.white)
              : (isLight ? Colors.grey.shade600 : Colors.grey.shade400),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, FontAwesomeIcons.wallet, isLight),
                    _buildNavItem(1, FontAwesomeIcons.arrowRightArrowLeft, isLight),
                    _buildNavItem(2, FontAwesomeIcons.handHoldingDollar, isLight),
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
