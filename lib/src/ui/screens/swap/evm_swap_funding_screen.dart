import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/swap_monitoring_service.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bottom_action_buttons.dart';
import 'package:ark_flutter/src/ui/widgets/swap/wallet_connect_button.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:flutter/material.dart';

/// Screen for funding an EVM→BTC swap via WalletConnect.
///
/// This screen handles:
/// 1. Connecting user's EVM wallet via WalletConnect
/// 2. Creating the swap with the connected address
/// 3. Executing approve() and createSwap() transactions
/// 4. Navigating to processing screen after successful funding
class EvmSwapFundingScreen extends StatefulWidget {
  final SwapToken sourceToken;
  final SwapToken targetToken;
  final String sourceAmount;
  final String targetAmount;
  final double usdAmount;

  const EvmSwapFundingScreen({
    super.key,
    required this.sourceToken,
    required this.targetToken,
    required this.sourceAmount,
    required this.targetAmount,
    required this.usdAmount,
  });

  @override
  State<EvmSwapFundingScreen> createState() => _EvmSwapFundingScreenState();
}

class _EvmSwapFundingScreenState extends State<EvmSwapFundingScreen> {
  final WalletConnectService _walletService = WalletConnectService();
  final LendaSwapService _swapService = LendaSwapService();

  bool _isCreatingSwap = false;
  bool _isFunding = false;
  String? _error;
  EvmToBtcSwapResult? _swapResult;

  // Funding steps
  FundingStep _currentStep = FundingStep.connectWallet;

  @override
  void initState() {
    super.initState();
    _walletService.addListener(_onWalletStateChanged);
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletStateChanged);
    super.dispose();
  }

  void _onWalletStateChanged() {
    if (mounted) {
      setState(() {
        if (_walletService.isConnected &&
            _currentStep == FundingStep.connectWallet) {
          _currentStep = FundingStep.createSwap;
        }
      });
    }
  }

  EvmChain get _evmChain {
    final chainId = widget.sourceToken.chainId.toLowerCase();
    if (chainId.contains('ethereum') || chainId == 'eth') {
      return EvmChain.ethereum;
    }
    return EvmChain.polygon;
  }

  Future<void> _createSwap() async {
    final validationError = _validateWalletConnection();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isCreatingSwap = true;
      _error = null;
    });

    try {
      final addresses = await ark_api.address();
      final connectedAddress = _walletService.connectedAddress!;

      logger.i(
          'Creating swap: ${widget.usdAmount} ${widget.sourceToken.tokenId} → BTC');

      final result = await _swapService.createBuyBtcSwap(
        targetArkAddress: addresses.offchain,
        userEvmAddress: connectedAddress,
        sourceAmount: widget.usdAmount,
        sourceToken: widget.sourceToken.tokenId,
        sourceChain: widget.sourceToken.chainId,
      );

      setState(() {
        _swapResult = result;
        _currentStep = FundingStep.fundSwap;
      });

      logger.i('Swap created: ${result.swapId}');
    } catch (e) {
      logger.e('Failed to create swap: $e');
      setState(() => _error = _parseError(e.toString()));
    } finally {
      setState(() => _isCreatingSwap = false);
    }
  }

  /// Validate wallet connection and return error message if invalid
  String? _validateWalletConnection() {
    if (!_walletService.isConnected ||
        _walletService.connectedAddress == null) {
      return 'Please connect your wallet first';
    }

    final address = _walletService.connectedAddress!;

    if (_walletService.isSolanaAddress && !_walletService.isEvmAddress) {
      return 'Solana wallets are not supported. Please connect a Polygon or Ethereum wallet.';
    }

    if (!address.startsWith('0x') || address.length != 42) {
      return 'Invalid wallet address. Please connect an EVM-compatible wallet.';
    }

    return null;
  }

  Future<void> _fundSwap() async {
    if (_swapResult == null) {
      setState(() => _error = 'No swap to fund');
      return;
    }

    final createSwapTx = _swapResult!.createSwapTx;
    if (createSwapTx == null || createSwapTx.isEmpty) {
      setState(() => _error = 'Missing createSwap transaction data');
      return;
    }

    setState(() {
      _isFunding = true;
      _error = null;
      _currentStep = FundingStep.approvingToken;
    });

    try {
      await _walletService.ensureCorrectChain(_evmChain);

      logger.i('Approving token spending...');
      await _walletService.approveToken(
        tokenAddress: _swapResult!.sourceTokenAddress,
        spenderAddress: _swapResult!.evmHtlcAddress,
      );

      logger.i('Token approved, creating swap on HTLC...');
      setState(() => _currentStep = FundingStep.creatingHtlc);

      final txHash = await _walletService.sendTransaction(
        to: _swapResult!.evmHtlcAddress,
        data: createSwapTx,
      );

      logger.i('Swap funded! TX: $txHash');
      setState(() => _currentStep = FundingStep.completed);

      // Start monitoring and navigate back to wallet
      _onSwapFundingSuccess();
    } catch (e) {
      logger.e('Failed to fund swap: $e');
      setState(() {
        _error = _parseError(e.toString());
        _currentStep = FundingStep.fundSwap;
      });
    } finally {
      setState(() => _isFunding = false);
    }
  }

  /// Handle successful swap funding - navigate back to wallet
  void _onSwapFundingSuccess() {
    if (!mounted || _swapResult == null) return;

    // Start background monitoring for auto-claim
    SwapMonitoringService().startMonitoringSwap(_swapResult!.swapId);

    // Navigate back to wallet
    Navigator.of(context).popUntil((route) => route.isFirst);
    PaymentMonitoringService().switchToWalletTab();
    OverlayService().showSuccess('Swap initiated! Processing in background...');
  }

  /// Parse error message into user-friendly text
  String _parseError(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('user rejected') ||
        errorLower.contains('user denied')) {
      return 'Transaction was rejected in wallet';
    }
    if (errorLower.contains('insufficient funds') ||
        errorLower.contains('insufficient balance')) {
      return 'Insufficient balance for this transaction';
    }
    if (errorLower.contains('network') || errorLower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Clean up error message
    String cleanError = error;
    if (cleanError.contains('Exception:')) {
      cleanError = cleanError.split('Exception:').last.trim();
    }
    return cleanError.length > 100
        ? '${cleanError.substring(0, 97)}...'
        : cleanError;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: 'Fund Swap',
        transparent: true,
      ),
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for app bar
                const SizedBox(height: AppTheme.cardPadding * 2),

                // Swap summary
                _buildSwapSummary(isDark),
                const SizedBox(height: AppTheme.cardPadding),

                // Steps progress
                _buildStepsProgress(isDark),
                const SizedBox(height: AppTheme.cardPadding),

                // Error message
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.cardPadding),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMid),
                      border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.cardPadding),
                ],

                // Current step content (non-button parts)
                _buildCurrentStepContent(isDark),

                // Extra space at bottom for button
                const SizedBox(height: AppTheme.cardPadding * 6),
              ],
            ),
          ),
          // Floating action button at bottom (overlays content with gradient)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomButton(isDark),
          ),
        ],
      ),
    );
  }

  /// Build the bottom button based on current step
  Widget _buildBottomButton(bool isDark) {
    switch (_currentStep) {
      case FundingStep.connectWallet:
        if (_walletService.isConnected) {
          return BottomCenterButton(
            title: 'Continue with ${_walletService.shortAddress}',
            onTap: () {
              setState(() => _currentStep = FundingStep.createSwap);
            },
          );
        }
        // For WalletConnectButton, wrap in BottomActionContainer
        return BottomActionContainer(
          child: WalletConnectButton(
            chain: _evmChain,
            onConnected: () {
              setState(() => _currentStep = FundingStep.createSwap);
            },
          ),
        );
      case FundingStep.createSwap:
        return BottomCenterButton(
          title: _isCreatingSwap ? 'Creating Swap...' : 'Create Swap',
          state: _isCreatingSwap ? ButtonState.loading : ButtonState.idle,
          onTap: _isCreatingSwap ? null : _createSwap,
        );
      case FundingStep.fundSwap:
        return BottomCenterButton(
          title: 'Approve & Fund Swap',
          onTap: _fundSwap,
        );
      case FundingStep.approvingToken:
      case FundingStep.creatingHtlc:
      case FundingStep.completed:
        // No button during these steps
        return const SizedBox.shrink();
    }
  }

  Widget _buildSwapSummary(bool isDark) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          children: [
            // From - You send
            Row(
              children: [
                TokenIcon(token: widget.sourceToken, size: 40),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You send',
                        style: TextStyle(
                          color: isDark ? AppTheme.white60 : AppTheme.black60,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${widget.sourceAmount} ${widget.sourceToken.symbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.sourceToken.network,
                        style: TextStyle(
                          color: isDark ? AppTheme.white60 : AppTheme.black60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // Divider with arrow
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 20,
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding),
            // To - You receive
            Row(
              children: [
                TokenIcon(token: widget.targetToken, size: 40),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You receive',
                        style: TextStyle(
                          color: isDark ? AppTheme.white60 : AppTheme.black60,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${widget.targetAmount} ${widget.targetToken.symbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.targetToken.network,
                        style: TextStyle(
                          color: isDark ? AppTheme.white60 : AppTheme.black60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsProgress(bool isDark) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepRow(
              step: 1,
              title: 'Connect Wallet',
              isCompleted: _currentStep.index > FundingStep.connectWallet.index,
              isActive: _currentStep == FundingStep.connectWallet,
              isDark: isDark,
            ),
            _buildStepDivider(isDark),
            _buildStepRow(
              step: 2,
              title: 'Create Swap',
              isCompleted: _currentStep.index > FundingStep.createSwap.index,
              isActive: _currentStep == FundingStep.createSwap,
              isDark: isDark,
            ),
            _buildStepDivider(isDark),
            _buildStepRow(
              step: 3,
              title: 'Approve & Fund',
              isCompleted: _currentStep == FundingStep.completed,
              isActive: _currentStep.index >= FundingStep.fundSwap.index &&
                  _currentStep != FundingStep.completed,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required int step,
    required String title,
    required bool isCompleted,
    required bool isActive,
    required bool isDark,
  }) {
    Color circleColor;
    Color textColor;
    IconData? icon;

    if (isCompleted) {
      circleColor = Colors.green;
      textColor = Colors.green;
      icon = Icons.check;
    } else if (isActive) {
      circleColor = AppTheme.colorBitcoin;
      textColor = isDark ? Colors.white : Colors.black;
    } else {
      circleColor = isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.2);
      textColor = isDark
          ? Colors.white.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.4);
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: circleColor.withValues(alpha: isCompleted ? 1.0 : 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: circleColor),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isCompleted ? Colors.white : circleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (isActive && _isFunding) dotProgress(context, size: 14),
      ],
    );
  }

  Widget _buildStepDivider(bool isDark) {
    // Circle is 28px wide, center is at 14px, line is 2px wide
    // So margin-left should be 14 - 1 = 13 to center the line under the circles
    return Container(
      margin: const EdgeInsets.only(left: 13),
      height: 20,
      width: 2,
      color: isDark
          ? Colors.white.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.2),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case FundingStep.connectWallet:
        if (_walletService.isConnected) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWalletConnectedCard(isDark),
              const SizedBox(height: AppTheme.cardPadding),
              _buildHelpText(
                  'Continue with your connected wallet or switch to a different one.',
                  isDark),
            ],
          );
        }
        return _buildHelpText(
            'Connect your ${_evmChain.name} wallet to fund the swap.', isDark);

      case FundingStep.createSwap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletConnectedCard(isDark),
            const SizedBox(height: AppTheme.cardPadding),
            _buildHelpText(
                'Create the swap to get the funding details.', isDark),
          ],
        );

      case FundingStep.fundSwap:
      case FundingStep.approvingToken:
      case FundingStep.creatingHtlc:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_swapResult != null) ...[
              _buildSwapDetailsCard(isDark),
              const SizedBox(height: AppTheme.cardPadding),
            ],
            if (_currentStep == FundingStep.approvingToken)
              _buildProgressIndicator('Approving token...', isDark)
            else if (_currentStep == FundingStep.creatingHtlc)
              _buildProgressIndicator('Creating HTLC...', isDark)
            else ...[
              _buildHelpText(
                'Click below to approve and fund the swap. This will open your wallet for two transactions:',
                isDark,
              ),
              const SizedBox(height: 8),
              Text(
                '1. Approve ${widget.sourceToken.symbol} spending\n2. Create the HTLC lock',
                style: TextStyle(
                  color: isDark ? AppTheme.white80 : AppTheme.black80,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        );

      case FundingStep.completed:
        // This state is briefly shown before navigation
        return const Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: AppTheme.cardPadding),
              Text(
                'Swap funded!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
    }
  }

  /// Build wallet connected card with switch button
  Widget _buildWalletConnectedCard(bool isDark) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet Connected',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _walletService.shortAddress ?? '',
                    style: TextStyle(
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _disconnectWallet,
              child: Text(
                'Switch',
                style: TextStyle(
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build swap details card
  Widget _buildSwapDetailsCard(bool isDark) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swap Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
                'Swap ID', _truncateId(_swapResult!.swapId), isDark),
            _buildDetailRow(
                'HTLC', _truncateId(_swapResult!.evmHtlcAddress), isDark),
            _buildDetailRow(
                'You receive', '${_swapResult!.satsToReceive} sats', isDark),
            _buildDetailRow('Fee', '${_swapResult!.feeSats} sats', isDark),
          ],
        ),
      ),
    );
  }

  /// Build help text widget
  Widget _buildHelpText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppTheme.white60 : AppTheme.black60,
      ),
    );
  }

  /// Disconnect wallet and reset to connect step
  Future<void> _disconnectWallet() async {
    await _walletService.disconnect();
    setState(() {
      _currentStep = FundingStep.connectWallet;
      _error = null;
    });
  }

  /// Truncate ID for display
  String _truncateId(String id) {
    if (id.length <= 14) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.white60 : AppTheme.black60,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          dotProgress(context, size: 14),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum FundingStep {
  connectWallet,
  createSwap,
  fundSwap,
  approvingToken,
  creatingHtlc,
  completed,
}
