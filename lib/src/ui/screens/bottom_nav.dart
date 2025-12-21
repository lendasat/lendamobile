import 'dart:async';

import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
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

class _BottomNavState extends State<BottomNav> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  // Global payment monitoring
  bool _isMonitoringPayments = false;
  String? _arkAddress;
  String? _boardingAddress;

  // Track balance to detect payments received while backgrounded
  BigInt? _lastKnownBalance;

  // Key for WalletScreen to trigger refresh
  final GlobalKey<WalletScreenState> _walletKey = GlobalKey<WalletScreenState>();
  // Key for SwapScreen to unfocus text fields
  final GlobalKey<SwapScreenState> _swapKey = GlobalKey<SwapScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      WalletScreen(key: _walletKey, aspId: widget.aspId),
      SwapScreen(key: _swapKey),
      LoansScreen(aspId: widget.aspId),
    ];

    // Start global payment monitoring
    _initPaymentMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isMonitoringPayments = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Restart payment monitoring when app resumes
      logger.i("App resumed, restarting global payment monitoring");
      // Check for payments received while backgrounded
      _checkForMissedPayments();
      _restartPaymentMonitoring();
    } else if (state == AppLifecycleState.paused) {
      // Store current balance before pausing
      _storeCurrentBalance();
      // Stop monitoring when app is paused
      _isMonitoringPayments = false;
    }
  }

  /// Store the current balance before the app goes to background
  Future<void> _storeCurrentBalance() async {
    try {
      final balanceResult = await balance();
      _lastKnownBalance = balanceResult.offchain.totalSats;
      logger.i("Stored balance before pause: $_lastKnownBalance sats");
    } catch (e) {
      logger.e("Error storing balance before pause: $e");
    }
  }

  /// Check if any payments were received while the app was backgrounded
  Future<void> _checkForMissedPayments() async {
    if (_lastKnownBalance == null) return;

    try {
      final balanceResult = await balance();
      final currentBalance = balanceResult.offchain.totalSats;
      final previousBalance = _lastKnownBalance!;

      logger.i("Checking for missed payments - Previous: $previousBalance, Current: $currentBalance");

      if (currentBalance > previousBalance) {
        final difference = currentBalance - previousBalance;
        logger.i("Balance increased by $difference sats while backgrounded!");

        // Get the latest transaction to show in the overlay
        final transactions = await txHistory();
        if (transactions.isNotEmpty) {
          // Find the most recent incoming transaction
          for (final tx in transactions) {
            final BigInt txAmount = tx.map(
              boarding: (t) => t.amountSats,
              round: (t) => t.amountSats,
              redeem: (t) => t.amountSats,
            ) as BigInt;

            final txid = tx.map(
              boarding: (t) => t.txid,
              round: (t) => t.txid,
              redeem: (t) => t.txid,
            );

            // Check if this is a positive (incoming) transaction
            if (txAmount > BigInt.zero) {
              final overlayService = PaymentOverlayService();
              if (!overlayService.suppressPaymentNotifications && mounted) {
                // Create a PaymentReceived object for the overlay
                final payment = PaymentReceived(
                  txid: txid,
                  amountSats: txAmount,
                );

                overlayService.showPaymentReceivedOverlay(
                  context: context,
                  payment: payment,
                  onDismiss: () {
                    _walletKey.currentState?.fetchWalletData();
                  },
                );
              }
              break; // Only show overlay for the most recent incoming tx
            }
          }
        }

        // Refresh wallet data
        _walletKey.currentState?.fetchWalletData();
      }

      // Update the last known balance
      _lastKnownBalance = currentBalance;
    } catch (e) {
      logger.e("Error checking for missed payments: $e");
    }
  }

  Future<void> _initPaymentMonitoring() async {
    try {
      // Get wallet addresses for monitoring
      final addresses = await address();
      _arkAddress = addresses.offchain;
      _boardingAddress = addresses.boarding;
      logger.i("Initialized global payment monitoring");
      logger.i("Ark address: $_arkAddress");
      logger.i("Boarding address: $_boardingAddress");

      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error initializing payment monitoring: $e");
    }
  }

  Future<void> _restartPaymentMonitoring() async {
    if (_arkAddress == null && _boardingAddress == null) {
      await _initPaymentMonitoring();
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      _startPaymentMonitoring();
    }
  }

  Future<void> _startPaymentMonitoring() async {
    if (_isMonitoringPayments) return;
    if (_arkAddress == null && _boardingAddress == null) return;

    _isMonitoringPayments = true;

    while (_isMonitoringPayments && mounted) {
      try {
        logger.d("Waiting for payment globally...");

        final payment = await waitForPayment(
          arkAddress: _arkAddress,
          boardingAddress: _boardingAddress,
          timeoutSeconds: BigInt.from(300), // 5 minute timeout
        );

        if (!mounted) return;

        logger.i(
            "Global payment received! TXID: ${payment.txid}, Amount: ${payment.amountSats} sats");

        // Check if notifications are suppressed (e.g., during swap/send operations)
        final overlayService = PaymentOverlayService();
        if (overlayService.suppressPaymentNotifications) {
          logger.i("Payment notification suppressed (likely change from outgoing tx)");
        } else {
          // Show the payment overlay
          overlayService.showPaymentReceivedOverlay(
            context: context,
            payment: payment,
            onDismiss: () {
              // Refresh wallet data
              _walletKey.currentState?.fetchWalletData();
            },
          );
        }

        // Always refresh wallet data (even if notification suppressed)
        _walletKey.currentState?.fetchWalletData();

        // Small delay before restarting monitoring
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        final errorStr = e.toString().toLowerCase();

        // Expected errors - just restart monitoring
        final isExpectedError = errorStr.contains('timeout') ||
            errorStr.contains('transport error') ||
            errorStr.contains('connectionaborted') ||
            errorStr.contains('connection aborted') ||
            errorStr.contains('stream ended') ||
            errorStr.contains('h2 protocol error') ||
            errorStr.contains('canceled') ||
            errorStr.contains('cancelled');

        if (!isExpectedError) {
          logger.e("Error in global payment monitoring: $e");
        }

        // Small delay before retrying
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _onItemTapped(int index) {
    // Dismiss keyboard and unfocus swap screen when switching tabs
    FocusScope.of(context).unfocus();
    _swapKey.currentState?.unfocusAll();
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
