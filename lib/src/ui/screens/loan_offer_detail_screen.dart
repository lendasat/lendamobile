import 'dart:async';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/contract_detail_screen.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';

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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _durationController;
  late TextEditingController _addressController;

  bool _isCreating = false;
  String _processingStep = 'Processing...';
  double _calculatedInterest = 0;
  double _originationFee = 0;
  double _originationFeeAmount = 0;

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
  }

  @override
  void dispose() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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

      logger.i('[Loan] Creating contract: offer=${widget.offer.id}, amount=\$$amount, duration=$duration days');

      // Create the contract - initially in "Requested" status
      var contract = await _lendasatService.createContract(
        offerId: widget.offer.id,
        loanAmount: amount,
        durationDays: duration,
        borrowerLoanAddress: address,
      );

      logger.i('[Loan] Contract ${contract.id}: status=${contract.statusText}, collateral=${contract.effectiveCollateralSats} sats');

      // If contract not yet ready, poll for approval
      // Use effectiveCollateralSats which falls back to initialCollateralSats
      if (contract.contractAddress == null || contract.effectiveCollateralSats <= 0) {
        if (mounted) {
          setState(() => _processingStep = 'Waiting for approval...');
        }

        // Poll until approved or timeout
        contract = await _waitForContractApproval(contract.id);
      }

      // Now we have an approved contract with collateral info
      if (mounted) {
        setState(() => _processingStep = 'Sending collateral...');
      }

      // Send collateral using effectiveCollateralSats (has initialCollateralSats fallback)
      final collateralSats = BigInt.from(contract.effectiveCollateralSats);
      final collateralAddress = contract.contractAddress!;

      logger.i('[Loan] Sending $collateralSats sats to $collateralAddress');

      final txid = await ark_api.send(
        address: collateralAddress,
        amountSats: collateralSats,
      );

      logger.i('[Loan] Collateral sent! TXID: $txid');

      // Track analytics
      await AnalyticsService().trackLoanTransaction(
        amountSats: contract.effectiveCollateralSats,
        type: 'borrow',
        loanId: contract.id,
        interestRate: widget.offer.interestRate,
        durationDays: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collateral sent! Loan is being processed.'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to contract detail - it will show live status updates
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailScreen(contractId: contract.id),
          ),
        );
      }
    } catch (e) {
      logger.e('[Loan] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
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

      logger.d('[Loan] Poll ${attempt + 1}/$_maxPollingAttempts: status=${contract.statusText}, '
          'address=${contract.contractAddress != null ? "present" : "null"}, '
          'effectiveCollateral=${contract.effectiveCollateralSats} sats');

      // Check if contract is ready (has collateral address and amount)
      if (contract.contractAddress != null && contract.effectiveCollateralSats > 0) {
        logger.i('[Loan] Contract approved! Collateral: ${contract.effectiveCollateralSats} sats to ${contract.contractAddress}');
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
      throw Exception('Collateral details pending. Check your contracts in a moment.');
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

  @override
  Widget build(BuildContext context) {
    return ArkScaffold(
      context: context,
      appBar: ArkAppBar(
        context: context,
        text: 'Loan Offer',
        onTap: _isCreating ? null : () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offer header
                  _buildOfferHeader(),
                  const SizedBox(height: AppTheme.cardPadding),

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

                  // Create button
                  LongButtonWidget(
                    title: _isCreating ? 'Processing...' : 'Create Loan Request',
                buttonType:
                    widget.offer.isAvailable && !_isCreating && _lendasatService.isAuthenticated
                        ? ButtonType.primary
                        : ButtonType.secondary,
                onTap: widget.offer.isAvailable && !_isCreating && _lendasatService.isAuthenticated
                    ? _createContract
                    : null,
              ),

              if (!_lendasatService.isAuthenticated)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.elementSpacing),
                  child: Text(
                    'Please sign in to create a loan request',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
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
                      const CircularProgressIndicator(
                        color: AppTheme.colorBitcoin,
                      ),
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

  Widget _buildOfferHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.offer.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildAssetChip(widget.offer.loanAssetDisplayName, isLoan: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
            _buildAssetChip(widget.offer.collateralAssetDisplayName),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.offer.isAvailable
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.offer.isAvailable
              ? AppTheme.successColor.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        widget.offer.isAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: widget.offer.isAvailable
                  ? AppTheme.successColor
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildAssetChip(String label, {bool isLoan = false}) {
    final color = isLoan ? Theme.of(context).colorScheme.primary : AppTheme.colorBitcoin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isLoan ? Icons.monetization_on : Icons.lock, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
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
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  Theme.of(context).colorScheme.primary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.offer.lender.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
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
                        color: AppTheme.successColor,
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
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
          _buildDetailRow('Interest Rate', widget.offer.interestRatePercent),
          _buildDetailRow('Loan Amount', widget.offer.loanAmountRange),
          _buildDetailRow('Duration', widget.offer.durationRange),
          _buildDetailRow(
            'Min LTV',
            '${(widget.offer.minLtv * 100).toStringAsFixed(0)}%',
          ),
          _buildDetailRow(
            'Payout',
            widget.offer.loanPayout == LoanPayout.direct
                ? 'Direct'
                : widget.offer.loanPayout == LoanPayout.moonCardInstant
                    ? 'Moon Card Instant'
                    : 'Indirect',
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_input_component_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Configure Your Loan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Amount input
          _buildSpecialField(
            label: 'LOAN AMOUNT',
            controller: _amountController,
            prefix: r'$',
            hint: '0.00',
            helper: 'Min \$${widget.offer.loanAmountMin.toStringAsFixed(0)} - Max \$${widget.offer.loanAmountMax.toStringAsFixed(0)}',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null) return 'Invalid amount';
              if (amount < widget.offer.loanAmountMin) return 'Minimum \$${widget.offer.loanAmountMin.toStringAsFixed(0)}';
              if (amount > widget.offer.loanAmountMax) return 'Maximum \$${widget.offer.loanAmountMax.toStringAsFixed(0)}';
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
            helper: 'Min ${widget.offer.durationDaysMin} - Max ${widget.offer.durationDaysMax} days',
            keyboardType: TextInputType.number,
            validator: (value) {
              final duration = int.tryParse(value ?? '');
              if (duration == null) return 'Invalid duration';
              if (duration < widget.offer.durationDaysMin) return 'Min ${widget.offer.durationDaysMin} days';
              if (duration > widget.offer.durationDaysMax) return 'Max ${widget.offer.durationDaysMax} days';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Address input
          _buildSpecialField(
            label: 'PAYOUT ADDRESS',
            controller: _addressController,
            hint: 'Recipient address',
            helper: 'Where you will receive the loan funds.',
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            },
          ),
        ],
      ),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), width: 1),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              Row(
                children: [
                  Icon(
                    Icons.summarize_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loan Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
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
        const SizedBox(height: AppTheme.cardPadding),
        // Collateral Card
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.colorBitcoin.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
          ),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            customColor: AppTheme.colorBitcoin.withValues(alpha: 0.03),
            borderRadius: AppTheme.borderRadiusMid,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppTheme.colorBitcoin,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REQUIRED COLLATERAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.colorBitcoin,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'CALCULATED ON SUBMIT',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colorBitcoin,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on ${(widget.offer.minLtv * 100).toStringAsFixed(0)}% LTV at current market price',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
              color: highlight ? AppTheme.colorBitcoin : (isLarge ? Theme.of(context).colorScheme.primary : null),
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
