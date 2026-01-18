import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bottom_action_buttons.dart';
import 'package:ark_flutter/src/ui/screens/loans/contract_detail_screen.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Screen to view loan offer details and create a contract.
class LoanOfferDetailScreen extends StatefulWidget {
  final LoanOffer offer;

  const LoanOfferDetailScreen({
    super.key,
    required this.offer,
  });

  @override
  State<LoanOfferDetailScreen> createState() => _LoanOfferDetailScreenState();
}

class _LoanOfferDetailScreenState extends State<LoanOfferDetailScreen> {
  final LendasatService _lendasatService = LendasatService();
  final WalletConnectService _walletConnectService = WalletConnectService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _durationController;
  late TextEditingController _addressController;

  bool _isCreating = false;
  String _processingStep = 'Processing...';
  double _calculatedInterest = 0;
  double _originationFee = 0;
  double _originationFeeAmount = 0;
  bool _addressFromWallet = false;

  // Polling configuration
  static const int _maxPollingAttempts = 60; // 60 attempts = ~60 seconds
  static const Duration _pollingInterval = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.offer.loanAmountMin.toStringAsFixed(0),
    );
    _durationController = TextEditingController(
      text: widget.offer.durationDaysMin.toString(),
    );
    _addressController = TextEditingController();
    _calculateLoanTerms();

    // Prefill address from connected wallet if available
    _prefillFromConnectedWallet();

    // Listen to wallet connection changes
    _walletConnectService.addListener(_onWalletConnectionChanged);
  }

  void _onWalletConnectionChanged() {
    if (mounted) {
      _prefillFromConnectedWallet();
    }
  }

  Future<void> _prefillFromConnectedWallet() async {
    if (_walletConnectService.isConnected &&
        _walletConnectService.isEvmAddress) {
      // Loans always use Polygon - ensure we're on the correct chain first
      try {
        await _walletConnectService.ensureCorrectChain(EvmChain.polygon);
      } catch (e) {
        logger.e('Failed to switch to Polygon: $e');
      }

      // Then get the Polygon address
      final address = _walletConnectService.connectedAddress;
      if (address != null && address.startsWith('0x') && mounted) {
        setState(() {
          _addressController.text = address;
          _addressFromWallet = true;
        });
      }
    }
  }

  Future<void> _connectWallet() async {
    try {
      if (!_walletConnectService.isInitialized) {
        await _walletConnectService.initialize(context);
      }
      await _walletConnectService.openModal();

      // After connecting, switch to Polygon and get address
      // Loans ALWAYS use Polygon for USDC payouts
      if (_walletConnectService.isConnected) {
        await _walletConnectService.ensureCorrectChain(EvmChain.polygon);
        // Manually trigger prefill after chain switch
        await _prefillFromConnectedWallet();
      }
    } catch (e) {
      logger.e('Error connecting wallet: $e');
      OverlayService().showError('Failed to connect wallet');
    }
  }

  @override
  void dispose() {
    _walletConnectService.removeListener(_onWalletConnectionChanged);
    _amountController.dispose();
    _durationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _calculateLoanTerms() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final duration = int.tryParse(_durationController.text) ?? 0;

    // Calculate interest (simple interest)
    final annualRate = widget.offer.interestRate;
    _calculatedInterest = amount * annualRate * (duration / 365);

    // Get origination fee (as decimal, e.g. 0.01 = 1%)
    _originationFee = widget.offer.getOriginationFee(duration);
    _originationFeeAmount = amount * _originationFee;

    // NOTE: Collateral amount is NOT calculated locally.
    // LendaSat API provides the exact collateral amount after contract approval.
    // This matches the lendasat/wallet web app approach.

    setState(() {});
  }

  Future<void> _createContract() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_lendasatService.isAuthenticated) {
      OverlayService().showError('Please sign in first');
      return;
    }

    setState(() {
      _isCreating = true;
      _processingStep = 'Creating loan request...';
    });

    // Suppress payment notifications during collateral send
    PaymentOverlayService().startSuppression();

    try {
      final amount = double.parse(_amountController.text);
      final duration = int.parse(_durationController.text);
      final address = _addressController.text.trim();

      logger.i(
          '[Loan] Creating contract: offer=${widget.offer.id}, amount=\$$amount, duration=$duration days');

      // Create the contract - initially in "Requested" status
      var contract = await _lendasatService.createContract(
        offerId: widget.offer.id,
        loanAmount: amount,
        durationDays: duration,
        borrowerLoanAddress: address,
      );

      logger.i(
          '[Loan] Contract ${contract.id}: status=${contract.statusText}, collateral=${contract.effectiveCollateralSats} sats');

      // If contract not yet ready, poll for approval
      // Use effectiveCollateralSats which falls back to initialCollateralSats
      if (contract.contractAddress == null ||
          contract.effectiveCollateralSats <= 0) {
        if (mounted) {
          setState(() => _processingStep = 'Waiting for approval...');
        }

        // Poll until approved or timeout
        contract = await _waitForContractApproval(contract.id);
      }

      // Navigate to contract detail screen
      // User will manually click "Pay Collateral" button to send funds
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailScreen(
              contractId: contract.id,
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('[Loan] Error: $e');
      if (mounted) {
        OverlayService().showError('Failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
      Future.delayed(const Duration(seconds: 5), () {
        PaymentOverlayService().stopSuppression();
      });
    }
  }

  /// Polls the contract status until it's approved and has collateral info.
  /// Throws an exception if it times out or the contract is rejected.
  Future<Contract> _waitForContractApproval(String contractId) async {
    logger.i('[Loan] Waiting for contract $contractId to be approved...');

    for (int attempt = 0; attempt < _maxPollingAttempts; attempt++) {
      await Future.delayed(_pollingInterval);

      if (!mounted) {
        throw Exception('Screen closed');
      }

      final contract = await _lendasatService.getContract(contractId);

      logger.d(
          '[Loan] Poll ${attempt + 1}/$_maxPollingAttempts: status=${contract.statusText}, '
          'address=${contract.contractAddress != null ? "present" : "null"}, '
          'effectiveCollateral=${contract.effectiveCollateralSats} sats');

      // Check if contract is ready (has collateral address and amount)
      if (contract.contractAddress != null &&
          contract.effectiveCollateralSats > 0) {
        logger.i(
            '[Loan] Contract approved! Collateral: ${contract.effectiveCollateralSats} sats to ${contract.contractAddress}');
        return contract;
      }

      // Check for rejection or cancellation
      if (contract.status == ContractStatus.rejected ||
          contract.status == ContractStatus.cancelled ||
          contract.status == ContractStatus.requestExpired) {
        throw Exception('Contract ${contract.statusText.toLowerCase()}');
      }

      // Update UI with progress - show different message once approved
      if (mounted) {
        final statusMsg = contract.status == ContractStatus.approved
            ? 'Preparing collateral...'
            : 'Waiting for approval...';
        setState(() => _processingStep = '$statusMsg (${attempt + 1}s)');
      }
    }

    // Timeout - provide helpful message based on current status
    final lastContract = await _lendasatService.getContract(contractId);
    if (lastContract.status == ContractStatus.approved) {
      throw Exception(
          'Collateral details pending. Check your contracts in a moment.');
    }
    throw Exception('Approval timeout. Please check your contracts later.');
  }

  Future<void> _openKycLink() async {
    if (widget.offer.kycLink != null) {
      try {
        await launchUrl(
          Uri.parse(widget.offer.kycLink!),
          customTabsOptions: CustomTabsOptions(
            colorSchemes: CustomTabsColorSchemes.defaults(
              toolbarColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        );
      } catch (e) {
        logger.e('Error opening KYC link: $e');
      }
    }
  }

  /// Show bottom sheet with LendaSat information
  void _showLendasatInfoSheet() {
    final l10n = AppLocalizations.of(context);

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.55,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: AppTheme.colorBitcoin,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                Expanded(
                  child: Text(
                    l10n?.aboutLendasat ?? 'About LendaSat',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardPadding * 1.5),
            // Description
            Text(
              l10n?.lendasatInfoDescription ??
                  'LendaSat is a Bitcoin peer-to-peer loan marketplace. We act as a platform that connects you with private lenders who provide the funds. Your Bitcoin is used as collateral, and you receive the loan amount directly. All transactions are secured through smart contracts on the Bitcoin network.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                    height: 1.6,
                  ),
            ),
            const Spacer(),
            // Learn more link with arrow
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('https://lendasat.com');
                if (await url_launcher.canLaunchUrl(url)) {
                  await url_launcher.launchUrl(url,
                      mode: url_launcher.LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.elementSpacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n?.learnMoreAboutLendasat ??
                          'Learn more about how LendaSat works',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        context: context,
        text: 'Loan Details',
        onTap: _isCreating ? null : () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppTheme.cardPadding,
                    right: AppTheme.cardPadding,
                    top: AppTheme.cardPadding,
                    // Extra bottom padding for floating button
                    bottom: AppTheme.cardPadding * 6,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Lender info
                        _buildLenderCard(),
                        const SizedBox(height: AppTheme.cardPadding),

                        // Offer details
                        _buildOfferDetails(),
                        const SizedBox(height: AppTheme.cardPadding),

                        // Loan configuration
                        _buildLoanConfiguration(),
                        const SizedBox(height: AppTheme.cardPadding),

                        // Calculated terms
                        _buildCalculatedTerms(),
                        const SizedBox(height: AppTheme.cardPadding),

                        // KYC warning if required
                        if (widget.offer.requiresKyc) ...[
                          _buildKycWarning(),
                          const SizedBox(height: AppTheme.cardPadding),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Floating action button at bottom
              _buildFloatingActionButton(),
            ],
          ),
          // Processing overlay
          if (_isCreating)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppTheme.cardPadding * 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      dotProgress(context),
                      const SizedBox(height: AppTheme.cardPadding),
                      Text(
                        _processingStep,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final isEnabled = widget.offer.isAvailable &&
        !_isCreating &&
        _lendasatService.isAuthenticated;

    return BottomCenterButton(
      title: _isCreating ? 'Processing...' : 'Create Loan Request',
      buttonType: isEnabled ? ButtonType.primary : ButtonType.secondary,
      onTap: isEnabled ? _createContract : null,
      bottomWidget: !_lendasatService.isAuthenticated
          ? Text(
              'Please sign in to create a loan request',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
              textAlign: TextAlign.center,
            )
          : null,
    );
  }

  Widget _buildLenderCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                widget.offer.lender.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.offer.lender.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (widget.offer.lender.vetted) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppTheme.colorBitcoin,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${widget.offer.lender.successfulContracts} successful loans',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showLendasatInfoSheet,
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferDetails() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offer Terms',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.cardPadding),
          // Collateral → Payout visual flow
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                // Collateral side
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'COLLATERAL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bitcoin',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '(Arkade)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
                // Payout side
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'PAYOUT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'USDC',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '(Polygon)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDetailRow(
              'Interest Rate', '${widget.offer.interestRatePercent} APY'),
          _buildDetailRow('Loan Amount', widget.offer.loanAmountRange),
          _buildDetailRow('Duration', widget.offer.durationRange),
          _buildDetailRow(
            'Min LTV',
            '${(widget.offer.minLtv * 100).toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanConfiguration() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure Your Loan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Amount input
          _buildSpecialField(
            label: 'LOAN AMOUNT',
            controller: _amountController,
            prefix: r'$',
            hint: '0.00',
            helper:
                'Min \$${widget.offer.loanAmountMin.toStringAsFixed(0)} - Max \$${widget.offer.loanAmountMax.toStringAsFixed(0)}',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null) return 'Invalid amount';
              if (amount < widget.offer.loanAmountMin)
                return 'Minimum \$${widget.offer.loanAmountMin.toStringAsFixed(0)}';
              if (amount > widget.offer.loanAmountMax)
                return 'Maximum \$${widget.offer.loanAmountMax.toStringAsFixed(0)}';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Duration input
          _buildSpecialField(
            label: 'DURATION (DAYS)',
            controller: _durationController,
            suffix: 'days',
            hint: '30',
            helper:
                'Min ${widget.offer.durationDaysMin} - Max ${widget.offer.durationDaysMax} days',
            keyboardType: TextInputType.number,
            validator: (value) {
              final duration = int.tryParse(value ?? '');
              if (duration == null) return 'Invalid duration';
              if (duration < widget.offer.durationDaysMin)
                return 'Min ${widget.offer.durationDaysMin} days';
              if (duration > widget.offer.durationDaysMax)
                return 'Max ${widget.offer.durationDaysMax} days';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Address input with wallet connect option
          _buildAddressField(),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isConnected = _walletConnectService.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'PAYOUT ADDRESS (POLYGON USDC)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
        ),
        // Connected wallet indicator (below label)
        if (_addressFromWallet) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 12,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 4),
              Text(
                'From connected wallet',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.successColor,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          cursorColor: Theme.of(context).colorScheme.primary,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0x...',
            helperText: _addressFromWallet
                ? null
                : 'Enter your Polygon wallet address to receive USDC.',
            helperStyle: TextStyle(
              fontSize: 10,
              color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _addressFromWallet
                      ? AppTheme.successColor.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                  width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 1),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
          onChanged: (value) {
            // If user manually edits, clear the "from wallet" indicator
            if (_addressFromWallet &&
                value != _walletConnectService.connectedAddress) {
              setState(() {
                _addressFromWallet = false;
              });
            }
            _calculateLoanTerms();
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            if (!value.trim().startsWith('0x') || value.trim().length != 42) {
              return 'Enter a valid Polygon address (0x...)';
            }
            return null;
          },
        ),

        // Connect wallet button (only show if not connected and address is empty)
        if (!isConnected && _addressController.text.isEmpty) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _connectWallet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Connect Wallet',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecialField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontSize: 9,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          cursorColor: Theme.of(context).colorScheme.primary,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix != null ? '$prefix ' : null,
            suffixText: suffix,
            helperText: helper,
            helperStyle: TextStyle(
              fontSize: 10,
              color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  width: 1),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
          keyboardType: keyboardType,
          onChanged: (_) => _calculateLoanTerms(),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCalculatedTerms() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final totalRepayment = amount + _calculatedInterest + _originationFeeAmount;

    return Column(
      children: [
        // Loan Summary Card
        GlassContainer(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.cardPadding),
              _buildSummaryRow('PRINCIPAL', '\$${amount.toStringAsFixed(2)}'),
              _buildSummaryRow(
                  'INTEREST', '\$${_calculatedInterest.toStringAsFixed(2)}'),
              if (_originationFee > 0)
                _buildSummaryRow(
                  'FEE (${(_originationFee * 100).toStringAsFixed(1)}%)',
                  '\$${_originationFeeAmount.toStringAsFixed(2)}',
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              _buildSummaryRow(
                'TOTAL REPAYMENT',
                '\$${totalRepayment.toStringAsFixed(2)}',
                isBold: true,
                isLarge: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool highlight = false,
    bool isLarge = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  fontSize: isLarge ? 11 : 9,
                  letterSpacing: 0.5,
                ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isLarge ? 18 : 14,
              color: highlight
                  ? Theme.of(context).colorScheme.primary
                  : (isLarge ? Theme.of(context).colorScheme.primary : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycWarning() {
    return GlassContainer(
      customColor: Colors.orange.withValues(alpha: 0.1),
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'KYC Required',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Text(
            'This lender requires identity verification before you can take this offer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          TextButton(
            onPressed: _openKycLink,
            child: const Text('Complete KYC'),
          ),
        ],
      ),
    );
  }
}
