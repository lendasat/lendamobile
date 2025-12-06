import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PayoutMethodsScreen extends StatefulWidget {
  final String? initialMethodId;

  const PayoutMethodsScreen({
    super.key,
    this.initialMethodId,
  });

  @override
  State<PayoutMethodsScreen> createState() => _PayoutMethodsScreenState();
}

class _PayoutMethodsScreenState extends State<PayoutMethodsScreen> {
  late String _selectedMethodId;

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
      appBar: ArkAppBar(
        context: context,
        hasBackButton: true,
        text: l10n.payoutMethods,
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
                "Choose Payout Method",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            // SEPA Bank Transfer
            _buildPayoutMethodTile(
              id: "sepa_bank_transfer",
              name: "SEPA Bank Transfer",
              icon: const Icon(Icons.account_balance),
            ),

            // UK Bank Transfer
            _buildPayoutMethodTile(
              id: "gbp_bank_transfer",
              name: "UK Bank Transfer",
              icon: const Icon(Icons.account_balance),
            ),

            // UK Open Banking
            _buildPayoutMethodTile(
              id: "gbp_open_banking_payment",
              name: "UK Open Banking",
              icon: const Icon(Icons.account_balance_outlined),
            ),

            // ACH Bank Transfer
            _buildPayoutMethodTile(
              id: "ach_bank_transfer",
              name: "ACH Bank Transfer",
              icon: const Icon(Icons.account_balance),
            ),

            // Credit or Debit Card
            _buildPayoutMethodTile(
              id: "credit_debit_card",
              name: "Credit or Debit Card",
              icon: const Icon(Icons.credit_card),
            ),

            // PayPal
            _buildPayoutMethodTile(
              id: "paypal",
              name: "PayPal",
              icon: const Icon(FontAwesomeIcons.paypal, size: 24),
            ),

            // Venmo
            _buildPayoutMethodTile(
              id: "venmo",
              name: "Venmo",
              icon: const Icon(Icons.payment),
            ),

            // MoonPay Balance
            _buildPayoutMethodTile(
              id: "moonpay_balance",
              name: "MoonPay Balance",
              icon: const Icon(Icons.account_balance_wallet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutMethodTile({
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
                  color: BitNetTheme.successColor,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
