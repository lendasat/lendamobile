import 'dart:async';
import 'package:ark_flutter/theme.dart';
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
  String _processingStatus = '';
  double _calculatedCollateral = 0;
  double _calculatedInterest = 0;
  double _originationFee = 0;
  double _originationFeeAmount = 0;

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

    // Calculate collateral needed (based on LTV)
    // Assuming BTC price ~$100,000 for demo calculation
    // In production, this would come from a price feed
    const btcPrice = 100000.0;
    final totalLoan = amount + _calculatedInterest + _originationFeeAmount;
    _calculatedCollateral = (totalLoan / widget.offer.minLtv) / btcPrice;

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

    // Check wallet balance first
    final balance = await ark_api.balance();
    final requiredSats = BigInt.from(_calculatedCollateral * 100000000);

    if (balance.offchain.confirmedSats < requiredSats) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient balance. Need ${_calculatedCollateral.toStringAsFixed(6)} BTC for collateral.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _isCreating = true;
      _processingStatus = 'Creating loan request...';
    });

    // Suppress payment notifications during collateral send to avoid showing
    // "payment received" when change from the outgoing transaction is detected
    PaymentOverlayService().startSuppression();

    try {
      final amount = double.parse(_amountController.text);
      final duration = int.parse(_durationController.text);
      final address = _addressController.text.trim();

      // Step 1: Create the contract
      final contract = await _lendasatService.createContract(
        offerId: widget.offer.id,
        loanAmount: amount,
        durationDays: duration,
        borrowerLoanAddress: address,
      );

      logger.i('Contract created: ${contract.id}, status: ${contract.status}');

      // Step 2: Wait for approval (auto-lender should approve quickly)
      if (mounted) {
        setState(() => _processingStatus = 'Waiting for approval...');
      }

      Contract approvedContract = contract;

      // Poll for approval (max 60 seconds)
      for (int i = 0; i < 30; i++) {
        if (!mounted) return;

        approvedContract = await _lendasatService.getContract(contract.id);

        if (approvedContract.status == ContractStatus.approved ||
            approvedContract.status == ContractStatus.collateralSeen ||
            approvedContract.status == ContractStatus.collateralConfirmed) {
          break;
        }

        if (approvedContract.status == ContractStatus.rejected ||
            approvedContract.status == ContractStatus.cancelled ||
            approvedContract.status == ContractStatus.requestExpired) {
          throw Exception('Loan request was ${approvedContract.statusText}');
        }

        await Future.delayed(const Duration(seconds: 2));
      }

      // Check if approved and has collateral address
      if (approvedContract.contractAddress == null) {
        throw Exception('No collateral address received. Status: ${approvedContract.statusText}');
      }

      // Step 3: Send collateral from Arkade wallet
      if (mounted) {
        setState(() => _processingStatus = 'Sending collateral...');
      }

      final collateralSats = BigInt.from(approvedContract.collateralSats.toInt());
      final collateralAddress = approvedContract.contractAddress!;

      logger.i('Sending $collateralSats sats to $collateralAddress');

      final txid = await ark_api.send(
        address: collateralAddress,
        amountSats: collateralSats,
      );

      logger.i('Collateral sent! TXID: $txid');

      // Step 4: Wait for collateral confirmation
      if (mounted) {
        setState(() => _processingStatus = 'Confirming collateral...');
      }

      // Poll for collateral confirmation (max 60 seconds)
      Contract finalContract = approvedContract;
      for (int i = 0; i < 30; i++) {
        if (!mounted) return;

        finalContract = await _lendasatService.getContract(contract.id);

        if (finalContract.status == ContractStatus.collateralSeen ||
            finalContract.status == ContractStatus.collateralConfirmed ||
            finalContract.status == ContractStatus.principalGiven) {
          break;
        }

        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan created and collateral deposited!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to contract detail
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailScreen(contractId: contract.id),
          ),
        );
      }
    } catch (e) {
      logger.e('Error creating contract: $e');
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
        setState(() {
          _isCreating = false;
          _processingStatus = '';
        });
      }
      // Stop suppression after a delay to allow change transaction to settle
      // without showing a "payment received" notification
      Future.delayed(const Duration(seconds: 5), () {
        PaymentOverlayService().stopSuppression();
      });
    }
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
                        _processingStatus,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.elementSpacing),
                      Text(
                        'Please wait...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
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
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.offer.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          Row(
            children: [
              _buildAssetChip(widget.offer.loanAssetDisplayName),
              const SizedBox(width: 8),
              const Icon(Icons.swap_horiz, size: 20),
              const SizedBox(width: 8),
              _buildAssetChip(widget.offer.collateralAssetDisplayName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.offer.isAvailable
            ? AppTheme.successColor.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.offer.isAvailable ? 'Available' : 'Unavailable',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: widget.offer.isAvailable
                  ? AppTheme.successColor
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAssetChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildLenderCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              widget.offer.lender.name[0].toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.offer.lender.vetted) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        size: 18,
                        color: AppTheme.successColor,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.offer.lender.successfulContracts} successful loans',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
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
    return GlassContainer(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure Your Loan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Amount input
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Loan Amount',
              hintText: 'Enter amount in USD',
              prefixText: '\$ ',
              helperText:
                  'Min: \$${widget.offer.loanAmountMin.toStringAsFixed(0)} - Max: \$${widget.offer.loanAmountMax.toStringAsFixed(0)}',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _calculateLoanTerms(),
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null) return 'Invalid amount';
              if (amount < widget.offer.loanAmountMin) {
                return 'Minimum: \$${widget.offer.loanAmountMin.toStringAsFixed(0)}';
              }
              if (amount > widget.offer.loanAmountMax) {
                return 'Maximum: \$${widget.offer.loanAmountMax.toStringAsFixed(0)}';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Duration input
          TextFormField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: 'Duration (days)',
              hintText: 'Enter duration in days',
              helperText:
                  'Min: ${widget.offer.durationDaysMin} - Max: ${widget.offer.durationDaysMax} days',
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _calculateLoanTerms(),
            validator: (value) {
              final duration = int.tryParse(value ?? '');
              if (duration == null) return 'Invalid duration';
              if (duration < widget.offer.durationDaysMin) {
                return 'Minimum: ${widget.offer.durationDaysMin} days';
              }
              if (duration > widget.offer.durationDaysMax) {
                return 'Maximum: ${widget.offer.durationDaysMax} days';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.cardPadding),

          // Address input (required)
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Payout Address',
              hintText: 'Enter address to receive funds',
              helperText: 'Enter your wallet address to receive the loan payout.',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Payout address is required';
              }
              return null;
            },
          ),
        ],
      ),
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.cardPadding),
              _buildSummaryRow('Principal', '\$${amount.toStringAsFixed(2)}'),
              _buildSummaryRow(
                  'Interest', '\$${_calculatedInterest.toStringAsFixed(2)}'),
              if (_originationFee > 0)
                _buildSummaryRow(
                  'Origination Fee (${(_originationFee * 100).toStringAsFixed(1)}%)',
                  '\$${_originationFeeAmount.toStringAsFixed(2)}',
                ),
              const Divider(height: AppTheme.cardPadding),
              _buildSummaryRow(
                'Total Repayment',
                '\$${totalRepayment.toStringAsFixed(2)}',
                isBold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.cardPadding),
        // Collateral Card
        GlassContainer(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          customColor: AppTheme.colorBitcoin.withValues(alpha: 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppTheme.colorBitcoin,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Required Collateral',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.colorBitcoin,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.cardPadding),
              Center(
                child: Text(
                  '~${_calculatedCollateral.toStringAsFixed(6)} BTC',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colorBitcoin,
                      ),
                ),
              ),
              const SizedBox(height: AppTheme.elementSpacing),
              Center(
                child: Text(
                  'Based on ${(widget.offer.minLtv * 100).toStringAsFixed(0)}% LTV',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool highlight = false}) {
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
                  fontWeight: isBold ? FontWeight.bold : null,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: highlight ? AppTheme.colorBitcoin : null,
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
              SizedBox(width: 8),
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
