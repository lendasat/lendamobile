import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/rust/api/lendaswap_api.dart';
import 'package:ark_flutter/src/services/lendaswap_service.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_processing_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
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
    if (!_walletService.isConnected ||
        _walletService.connectedAddress == null) {
      setState(() => _error = 'Please connect your wallet first');
      return;
    }

    final connectedAddress = _walletService.connectedAddress!;

    // Validate EVM address format (should start with 0x and be 42 chars)
    if (_walletService.isSolanaAddress && !_walletService.isEvmAddress) {
      logger.w('Connected purely with Solana: $connectedAddress');
      setState(() => _error =
          'You connected with a Solana address. LendaSwap currently only supports Polygon and Ethereum for these swaps. If you are using Phantom, please make sure to select Polygon or Ethereum in the AppKit network selection.');
      return;
    }

    if (!connectedAddress.startsWith('0x') || connectedAddress.length != 42) {
      logger.e('Invalid EVM address format: $connectedAddress');
      setState(() => _error =
          'Invalid wallet address format. Please connect an EVM-compatible wallet (Polygon/Ethereum).');
      return;
    }

    setState(() {
      _isCreatingSwap = true;
      _error = null;
    });

    try {
      // Get Arkade address for receiving BTC
      final addresses = await ark_api.address();
      final arkadeAddress = addresses.offchain;

      logger.i('Creating swap with:');
      logger.i('  targetArkAddress: $arkadeAddress');
      logger.i('  userEvmAddress: $connectedAddress');
      logger.i('  sourceAmount: ${widget.usdAmount}');
      logger.i('  sourceToken: ${widget.sourceToken.tokenId}');
      logger.i('  sourceChain: ${widget.sourceToken.chainId}');

      // Create the swap with the connected EVM address
      final result = await _swapService.createBuyBtcSwap(
        targetArkAddress: arkadeAddress,
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
      logger.i('HTLC address: ${result.evmHtlcAddress}');
      logger.i(
          'createSwapTx: ${result.createSwapTx?.substring(0, 20) ?? "null"}...');
    } catch (e) {
      logger.e('Failed to create swap: $e');
      setState(() => _error = 'Failed to create swap: ${e.toString()}');
    } finally {
      setState(() => _isCreatingSwap = false);
    }
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
      // Ensure we're on the correct chain before transactions
      await _walletService.ensureCorrectChain(_evmChain);

      // Step 1: Approve token spending
      logger.i('Approving token spending...');
      await _walletService.approveToken(
        tokenAddress: _swapResult!.sourceTokenAddress,
        spenderAddress: _swapResult!.evmHtlcAddress,
      );

      logger.i('Token approved, creating swap on HTLC...');
      setState(() => _currentStep = FundingStep.creatingHtlc);

      // Step 2: Call createSwap on HTLC contract
      final txHash = await _walletService.sendTransaction(
        to: _swapResult!.evmHtlcAddress,
        data: createSwapTx,
      );

      logger.i('Swap funded! TX: $txHash');
      setState(() => _currentStep = FundingStep.completed);

      // Navigate to processing screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SwapProcessingScreen(
              swapId: _swapResult!.swapId,
              sourceToken: widget.sourceToken,
              targetToken: widget.targetToken,
              sourceAmount: widget.sourceAmount,
              targetAmount: widget.targetAmount,
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('Failed to fund swap: $e');
      setState(() {
        _error = 'Failed to fund swap: ${e.toString()}';
        _currentStep = FundingStep.fundSwap; // Reset to allow retry
      });
    } finally {
      setState(() => _isFunding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        context: context,
        text: 'Fund Swap',
        transparent: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // Extra space at bottom for floating button
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Floating buttons at bottom based on current step
          if (_currentStep == FundingStep.connectWallet)
            Positioned(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
              child: WalletConnectButton(
                chain: _evmChain,
                onConnected: () {
                  setState(() => _currentStep = FundingStep.createSwap);
                },
              ),
            ),
          if (_currentStep == FundingStep.createSwap)
            Positioned(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
              child: LongButtonWidget(
                title: _isCreatingSwap ? 'Creating Swap...' : 'Create Swap',
                customWidth: double.infinity,
                state: _isCreatingSwap ? ButtonState.loading : ButtonState.idle,
                onTap: _isCreatingSwap ? null : _createSwap,
              ),
            ),
          if (_currentStep == FundingStep.fundSwap)
            Positioned(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
              child: LongButtonWidget(
                title: 'Approve & Fund Swap',
                customWidth: double.infinity,
                onTap: _fundSwap,
              ),
            ),
        ],
      ),
    );
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
        if (isActive && _isFunding)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
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
        return Text(
          'Connect your ${_evmChain.name} wallet to fund the swap.',
          style: TextStyle(
            color: isDark ? AppTheme.white60 : AppTheme.black60,
          ),
        );

      case FundingStep.createSwap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
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
                              color:
                                  isDark ? AppTheme.white60 : AppTheme.black60,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Disconnect button to switch wallets
                    TextButton(
                      onPressed: () async {
                        await _walletService.disconnect();
                        setState(() {
                          _currentStep = FundingStep.connectWallet;
                          _error = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
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
            ),
            const SizedBox(height: AppTheme.cardPadding),
            Text(
              'Create the swap to get the funding details.',
              style: TextStyle(
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ],
        );

      case FundingStep.fundSwap:
      case FundingStep.approvingToken:
      case FundingStep.creatingHtlc:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_swapResult != null) ...[
              GlassContainer(
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
                      _buildDetailRow('Swap ID',
                          '${_swapResult!.swapId.substring(0, 8)}...', isDark),
                      _buildDetailRow(
                          'HTLC',
                          '${_swapResult!.evmHtlcAddress.substring(0, 10)}...',
                          isDark),
                      _buildDetailRow('You receive',
                          '${_swapResult!.satsToReceive} sats', isDark),
                      _buildDetailRow(
                          'Fee', '${_swapResult!.feeSats} sats', isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.cardPadding),
            ],
            if (_currentStep == FundingStep.approvingToken) ...[
              _buildProgressIndicator('Approving token...', isDark),
            ] else if (_currentStep == FundingStep.creatingHtlc) ...[
              _buildProgressIndicator('Creating HTLC...', isDark),
            ] else ...[
              Text(
                'Click below to approve and fund the swap. This will open your wallet for two transactions:',
                style: TextStyle(
                  color: isDark ? AppTheme.white60 : AppTheme.black60,
                ),
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
        return Column(
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: AppTheme.cardPadding),
            const Text(
              'Swap funded successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Navigating to swap status...',
              style: TextStyle(
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ],
        );
    }
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
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
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
