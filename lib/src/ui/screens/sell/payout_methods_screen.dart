import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';

class PayoutMethodsScreen extends StatefulWidget {
  const PayoutMethodsScreen({super.key});

  @override
  State<PayoutMethodsScreen> createState() => _PayoutMethodsScreenState();
}

class _PayoutMethodsScreenState extends State<PayoutMethodsScreen> {
  String? _selectedMethodId;

  final List<PayoutMethod> _payoutMethods = [
    PayoutMethod(
      id: 'sepa_bank_transfer',
      name: 'SEPA Bank Transfer',
      icon: Icons.account_balance,
    ),
    PayoutMethod(
      id: 'gbp_bank_transfer',
      name: 'UK Bank Transfer',
      icon: Icons.account_balance,
    ),
    PayoutMethod(
      id: 'gbp_open_banking_payment',
      name: 'UK Open Banking',
      icon: Icons.account_balance_outlined,
    ),
    PayoutMethod(
      id: 'ach_bank_transfer',
      name: 'ACH Bank Transfer',
      icon: Icons.account_balance,
    ),
    PayoutMethod(
      id: 'credit_debit_card',
      name: 'Credit or Debit Card',
      icon: Icons.credit_card,
    ),
    PayoutMethod(id: 'paypal', name: 'PayPal', icon: Icons.payment),
    PayoutMethod(id: 'venmo', name: 'Venmo', icon: Icons.payment),
    PayoutMethod(
      id: 'moonpay_balance',
      name: 'MoonPay Balance',
      icon: Icons.account_balance_wallet,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        backgroundColor: theme.primaryBlack,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.payoutMethods,
          style: TextStyle(color: theme.primaryWhite),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _payoutMethods.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8.0),
        itemBuilder: (context, index) {
          final method = _payoutMethods[index];
          final isSelected = _selectedMethodId == method.id;

          return Container(
            decoration: BoxDecoration(
              color: theme.secondaryBlack,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isSelected
                    ? Colors.orange
                    : theme.primaryWhite.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(method.icon, color: theme.primaryWhite),
              title: Text(
                method.name,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.orange)
                  : null,
              onTap: () async {
                setState(() {
                  _selectedMethodId = method.id;
                });

                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted && context.mounted) {
                  Navigator.pop(context, {
                    'id': method.id,
                    'name': method.name,
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class PayoutMethod {
  final String id;
  final String name;
  final IconData icon;

  PayoutMethod({required this.id, required this.name, required this.icon});
}
