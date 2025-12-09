import 'dart:io';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String? initialMethodId;

  const PaymentMethodsScreen({
    super.key,
    this.initialMethodId,
  });

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late String _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _selectedMethodId = widget.initialMethodId ?? 'credit_debit_card';
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
      appBar: ArkAppBar(
        context: context,
        hasBackButton: true,
        text: l10n.paymentMethods,
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
            ),

            // Google Pay
            _buildPaymentMethodTile(
              id: "google_pay",
              name: "Google Pay",
              icon: const Icon(FontAwesomeIcons.google),
            ),

            // Apple Pay (iOS only)
            if (Platform.isIOS)
              _buildPaymentMethodTile(
                id: "apple_pay",
                name: "Apple Pay",
                icon: const Icon(FontAwesomeIcons.applePay, size: 32),
              ),

            // PayPal
            _buildPaymentMethodTile(
              id: "paypal",
              name: "PayPal",
              icon: const Icon(FontAwesomeIcons.paypal, size: 32),
            ),

            // Stripe
            _buildPaymentMethodTile(
              id: "stripe",
              name: "Stripe",
              icon: const Icon(FontAwesomeIcons.stripe, size: 32),
            ),

            // SEPA Bank Payments
            _buildPaymentMethodTile(
              id: "sepa_bank_transfer",
              name: "SEPA Bank Payments",
              icon: const Icon(Icons.account_balance),
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
  }) {
    final isSelected = _selectedMethodId == id;

    return Padding(
      padding: const EdgeInsets.all(8.0),
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
