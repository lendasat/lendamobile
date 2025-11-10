import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String? _selectedMethodId;

  final List<PaymentMethod> _paymentMethods = [
    PaymentMethod(
      id: 'credit_debit_card',
      name: 'Credit or Debit Card',
      icon: Icons.credit_card,
    ),
    PaymentMethod(
      id: 'apple_pay',
      name: 'Apple Pay',
      icon: Icons.apple,
    ),
    PaymentMethod(
      id: 'google_pay',
      name: 'Google Pay',
      icon: Icons.g_mobiledata_outlined,
    ),
    PaymentMethod(
      id: 'sepa_bank_transfer',
      name: 'SEPA Bank Transfer',
      icon: Icons.account_balance,
    ),
    PaymentMethod(
      id: 'gbp_bank_transfer',
      name: 'UK Bank Transfer',
      icon: Icons.account_balance,
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
          AppLocalizations.of(context)!.paymentMethods,
          style: TextStyle(color: theme.primaryWhite),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _paymentMethods.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8.0),
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          final isSelected = _selectedMethodId == method.id;

          return Container(
            decoration: BoxDecoration(
              color: theme.secondaryBlack,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isSelected
                    ? Colors.blue
                    : theme.primaryWhite.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                method.icon,
                color: theme.primaryWhite,
              ),
              title: Text(
                method.name,
                style: TextStyle(
                  color: theme.primaryWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                    )
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

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
  });
}
