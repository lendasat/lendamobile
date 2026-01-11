import 'dart:io';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String? initialMethodId;
  final String providerId;

  const PaymentMethodsScreen({
    super.key,
    this.initialMethodId,
    this.providerId = 'coinbase',
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late String _selectedMethodId;

  // MoonPay fee structure by payment method
  // Source: https://support.moonpay.com/customers/docs/moonpay-fees
  static const Map<String, PaymentMethodFee> _moonpayFees = {
    'credit_debit_card': PaymentMethodFee(percentage: 4.5, minFee: 3.99),
    'google_pay': PaymentMethodFee(percentage: 4.5, minFee: 3.99),
    'apple_pay': PaymentMethodFee(percentage: 4.5, minFee: 3.99),
    'paypal': PaymentMethodFee(percentage: 4.5, minFee: 3.99),
    'stripe': PaymentMethodFee(percentage: 4.5, minFee: 3.99),
    'sepa_bank_transfer': PaymentMethodFee(percentage: 1.0, minFee: 3.99),
  };

  // Coinbase fee structure by payment method
  // Source: https://help.coinbase.com/en/coinbase/trading-and-funding/pricing-and-fees/fees
  static const Map<String, PaymentMethodFee> _coinbaseFees = {
    'credit_debit_card':
        PaymentMethodFee(percentage: 4.49, minFee: 0), // 3.99% + 0.5% spread
    'google_pay': PaymentMethodFee(percentage: 4.49, minFee: 0),
    'apple_pay': PaymentMethodFee(percentage: 4.49, minFee: 0),
    'paypal': PaymentMethodFee(percentage: 4.49, minFee: 0),
    'stripe': PaymentMethodFee(percentage: 4.49, minFee: 0),
    'sepa_bank_transfer':
        PaymentMethodFee(percentage: 1.99, minFee: 0), // 1.49% + 0.5% spread
  };

  Map<String, PaymentMethodFee> get _fees =>
      widget.providerId == 'coinbase' ? _coinbaseFees : _moonpayFees;

  @override
  void initState() {
    super.initState();
    _selectedMethodId = widget.initialMethodId ?? 'sepa_bank_transfer';
  }

  void _selectMethod(String id, String name) {
    setState(() {
      _selectedMethodId = id;
    });

    // Return result after brief delay for visual feedback
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.of(context).pop({
          'id': id,
          'name': name,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: true,
        text: l10n.paymentMethods,
        transparent: false,
        onTap: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
              child: Text(
                "Choose Payment Method",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            // Credit/Debit Card
            _buildPaymentMethodTile(
              id: "credit_debit_card",
              name: "Credit or Debit Card",
              icon: const Icon(Icons.wallet_rounded),
              fee: _fees['credit_debit_card'],
            ),

            // Google Pay
            _buildPaymentMethodTile(
              id: "google_pay",
              name: "Google Pay",
              icon: const Icon(FontAwesomeIcons.google),
              fee: _fees['google_pay'],
            ),

            // Apple Pay (iOS only)
            if (Platform.isIOS)
              _buildPaymentMethodTile(
                id: "apple_pay",
                name: "Apple Pay",
                icon: const Icon(FontAwesomeIcons.applePay, size: 32),
                fee: _fees['apple_pay'],
              ),

            // PayPal
            _buildPaymentMethodTile(
              id: "paypal",
              name: "PayPal",
              icon: const Icon(FontAwesomeIcons.paypal, size: 32),
              fee: _fees['paypal'],
            ),

            // Stripe
            _buildPaymentMethodTile(
              id: "stripe",
              name: "Stripe",
              icon: const Icon(FontAwesomeIcons.stripe, size: 32),
              fee: _fees['stripe'],
            ),

            // SEPA Bank Payments (lowest fee!)
            _buildPaymentMethodTile(
              id: "sepa_bank_transfer",
              name: "SEPA Bank Payments",
              icon: const Icon(Icons.account_balance),
              fee: _fees['sepa_bank_transfer'],
              isRecommended: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String name,
    required Widget icon,
    PaymentMethodFee? fee,
    bool isRecommended = false,
  }) {
    final isSelected = _selectedMethodId == id;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding,
        vertical: 8.0,
      ),
      child: GlassContainer(
        opacity: 0.05,
        child: ArkListTile(
          margin: EdgeInsets.zero,
          contentPadding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            top: 16.0,
          ),
          text: name,
          subtitle: fee != null
              ? Row(
                  children: [
                    Text(
                      '${fee.percentage}% fee',
                      style: TextStyle(
                        color: isRecommended
                            ? AppTheme.successColor
                            : Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight:
                            isRecommended ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Lowest Fee',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              : null,
          onTap: () => _selectMethod(id, name),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: icon,
          ),
          trailing: isSelected
              ? const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Fee structure for a payment method
class PaymentMethodFee {
  final double percentage;
  final double minFee;

  const PaymentMethodFee({
    required this.percentage,
    required this.minFee,
  });
}
