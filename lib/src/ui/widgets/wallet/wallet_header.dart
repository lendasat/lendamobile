import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import 'wallet_action_buttons.dart';
import 'wallet_balance_display.dart';
import 'wallet_boarding_balance.dart';
import 'wallet_locked_collateral.dart';
import 'wallet_mini_chart.dart';
import 'wallet_price_indicators.dart';

/// Combines the wallet header: gradient background, chart, top bar,
/// balance display, and action buttons into one cohesive widget.
class WalletHeader extends StatelessWidget {
  // Balance data
  final double totalBalance;
  final double btcPrice;
  final int lockedCollateralSats;
  final int boardingBalanceSats;
  final bool isSettling;
  final bool skipAutoSettle;

  // Chart data
  final List<WalletChartData> chartData;
  final bool isBalanceLoading;

  // Price change metrics
  final double percentChange;
  final bool isPositive;
  final double balanceChangeInFiat;

  // Gradient colors
  final Color gradientTopColor;
  final Color gradientBottomColor;

  // Recovery status
  final bool hasAnyRecovery;

  // Callbacks
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onScan;
  final VoidCallback onBuy;
  final VoidCallback onChart;
  final VoidCallback onSettings;
  final VoidCallback onSettleBoarding;

  const WalletHeader({
    super.key,
    required this.totalBalance,
    required this.btcPrice,
    required this.lockedCollateralSats,
    required this.boardingBalanceSats,
    required this.isSettling,
    required this.skipAutoSettle,
    required this.chartData,
    required this.isBalanceLoading,
    required this.percentChange,
    required this.isPositive,
    required this.balanceChangeInFiat,
    required this.gradientTopColor,
    required this.gradientBottomColor,
    required this.hasAnyRecovery,
    required this.onSend,
    required this.onReceive,
    required this.onScan,
    required this.onBuy,
    required this.onChart,
    required this.onSettings,
    required this.onSettleBoarding,
  });

  @override
  Widget build(BuildContext context) {
    // Get the top padding (status bar / notch / dynamic island height)
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Dynamic gradient background - extends into status bar area
        _buildDynamicGradient(context, topPadding),

        // Chart overlay
        Opacity(
          opacity: 0.1,
          child: _buildChartWidget(context, topPadding),
        ),

        // Main content with SafeArea for proper padding
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.cardPadding),
              _buildTopBar(context),
              const SizedBox(height: AppTheme.cardPadding * 1.5),
              WalletBalanceDisplay(
                balanceBtc: totalBalance,
                btcPrice: btcPrice,
              ),
              if (lockedCollateralSats > 0) ...[
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                WalletLockedCollateral(
                  lockedCollateralSats: lockedCollateralSats,
                  btcPrice: btcPrice,
                ),
              ],
              if (boardingBalanceSats > 0) ...[
                const SizedBox(height: AppTheme.elementSpacing * 0.5),
                WalletBoardingBalance(
                  boardingBalanceSats: boardingBalanceSats,
                  btcPrice: btcPrice,
                  isSettling: isSettling,
                  skipAutoSettle: skipAutoSettle,
                  onTap: onSettleBoarding,
                ),
              ],
              const SizedBox(height: AppTheme.elementSpacing),
              WalletPriceIndicators(
                percentChange: percentChange,
                isPositive: isPositive,
                balanceChangeInFiat: balanceChangeInFiat,
                btcPrice: btcPrice,
              ),
              const SizedBox(height: AppTheme.cardPadding * 1.5),
              WalletActionButtons(
                onSend: onSend,
                onReceive: onReceive,
                onScan: onScan,
                onBuy: onBuy,
              ),
              const SizedBox(height: AppTheme.cardPadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicGradient(BuildContext context, double topPadding) {
    return Container(
      // Add top padding to gradient height so it fills the notch/dynamic island area
      height: AppTheme.cardPadding * 12 + topPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.75, 1.0],
          colors: [
            gradientTopColor,
            gradientBottomColor,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildChartWidget(BuildContext context, double topPadding) {
    if (chartData.isEmpty || isBalanceLoading) {
      return SizedBox(height: AppTheme.cardPadding * 10 + topPadding);
    }

    return WalletMiniChart(
      data: chartData,
      lineColor: isPositive ? AppTheme.successColor : AppTheme.errorColor,
      // Add top padding to chart height so it aligns with gradient
      height: AppTheme.cardPadding * 10 + topPadding,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(), // Keep buttons right-aligned

          // Action buttons
          Row(
            children: [
              // Hide balance button
              Consumer<UserPreferencesService>(
                builder: (context, userPrefs, _) => RoundedButtonWidget(
                  size: AppTheme.cardPadding * 1.5,
                  iconSize: AppTheme.cardPadding * 0.65,
                  buttonType: ButtonType.transparent,
                  hitSlop: 4,
                  iconData: userPrefs.balancesVisible
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  onTap: userPrefs.toggleBalancesVisible,
                ),
              ),

              // Chart button
              RoundedButtonWidget(
                size: AppTheme.cardPadding * 1.5,
                iconSize: AppTheme.cardPadding * 0.65,
                buttonType: ButtonType.transparent,
                hitSlop: 4,
                iconData: FontAwesomeIcons.chartLine,
                onTap: onChart,
              ),
              const SizedBox(width: AppTheme.elementSpacing * 0.5),

              // Settings button with recovery status indicator
              _buildSettingsButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        RoundedButtonWidget(
          size: AppTheme.cardPadding * 1.5,
          buttonType: ButtonType.transparent,
          hitSlop: 4,
          iconData: Icons.settings,
          onTap: onSettings,
        ),
        // Only show red dot if NO recovery option has been set up
        if (!hasAnyRecovery)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.errorColor,
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
