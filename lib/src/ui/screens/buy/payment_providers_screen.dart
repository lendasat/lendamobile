import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Payment provider information
class PaymentProvider {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final Map<String, ProviderFee> feesByMethod;
  final bool isAvailable;

  const PaymentProvider({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.feesByMethod,
    this.isAvailable = true,
  });
}

/// Fee structure for a provider's payment method
class ProviderFee {
  final double percentage;
  final double? spread; // Additional spread on top of percentage
  final double? minFee;

  const ProviderFee({
    required this.percentage,
    this.spread,
    this.minFee,
  });

  double get totalFee => percentage + (spread ?? 0);
}

class PaymentProvidersScreen extends StatefulWidget {
  final String? initialProviderId;
  final String currentPaymentMethodId;

  const PaymentProvidersScreen({
    super.key,
    this.initialProviderId,
    required this.currentPaymentMethodId,
  });

  @override
  State<PaymentProvidersScreen> createState() => _PaymentProvidersScreenState();
}

class _PaymentProvidersScreenState extends State<PaymentProvidersScreen> {
  late String _selectedProviderId;

  // Available payment providers
  static const List<PaymentProvider> _providers = [
    PaymentProvider(
      id: 'coinbase',
      name: 'Coinbase',
      description: 'Trusted by 100M+ users worldwide',
      imagePath: 'assets/images/coinbase.png',
      feesByMethod: {
        'credit_debit_card': ProviderFee(percentage: 3.99, spread: 0.5),
        'google_pay': ProviderFee(percentage: 3.99, spread: 0.5),
        'apple_pay': ProviderFee(percentage: 3.99, spread: 0.5),
        'paypal': ProviderFee(percentage: 3.99, spread: 0.5),
        'sepa_bank_transfer': ProviderFee(percentage: 1.49, spread: 0.5),
        'ach_bank_transfer': ProviderFee(percentage: 1.49, spread: 0.5),
      },
    ),
    PaymentProvider(
      id: 'moonpay',
      name: 'MoonPay',
      description: 'Fast & reliable crypto purchases',
      imagePath: 'assets/images/moonpay.png',
      feesByMethod: {
        'credit_debit_card': ProviderFee(percentage: 4.5, minFee: 3.99),
        'google_pay': ProviderFee(percentage: 4.5, minFee: 3.99),
        'apple_pay': ProviderFee(percentage: 4.5, minFee: 3.99),
        'paypal': ProviderFee(percentage: 4.5, minFee: 3.99),
        'stripe': ProviderFee(percentage: 4.5, minFee: 3.99),
        'sepa_bank_transfer': ProviderFee(percentage: 1.0, minFee: 3.99),
      },
      isAvailable: false,
    ),
    PaymentProvider(
      id: 'bringin',
      name: 'Bringin',
      description: 'Buy Bitcoin with ease',
      imagePath: 'assets/images/bringin.png',
      feesByMethod: {
        'credit_debit_card': ProviderFee(percentage: 2.5),
        'sepa_bank_transfer': ProviderFee(percentage: 1.0),
      },
      isAvailable: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedProviderId = widget.initialProviderId ?? 'coinbase';
  }

  void _selectProvider(PaymentProvider provider) {
    if (!provider.isAvailable) return;

    setState(() {
      _selectedProviderId = provider.id;
    });

    // Return result after brief delay for visual feedback
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.of(context).pop({
          'id': provider.id,
          'name': provider.name,
        });
      }
    });
  }

  ProviderFee? _getFeeForCurrentMethod(PaymentProvider provider) {
    // Try exact match first
    if (provider.feesByMethod.containsKey(widget.currentPaymentMethodId)) {
      return provider.feesByMethod[widget.currentPaymentMethodId];
    }
    // Fallback to SEPA for bank transfers
    if (widget.currentPaymentMethodId.contains('bank') ||
        widget.currentPaymentMethodId.contains('sepa')) {
      return provider.feesByMethod['sepa_bank_transfer'];
    }
    // Fallback to card fee
    return provider.feesByMethod['credit_debit_card'];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: true,
        text: l10n.paymentProvider,
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
                l10n.chooseProvider,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ..._providers.map((provider) => _buildProviderTile(provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(PaymentProvider provider) {
    final isSelected = _selectedProviderId == provider.id;
    final fee = _getFeeForCurrentMethod(provider);
    final greyColor =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding,
        vertical: 8.0,
      ),
      child: GlassContainer(
        opacity: provider.isAvailable ? 0.05 : 0.02,
        child: ArkListTile(
          margin: EdgeInsets.zero,
          contentPadding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            top: 16.0,
          ),
          text: provider.name,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.description,
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: provider.isAvailable ? 0.7 : 0.4),
                  fontSize: 12,
                ),
              ),
              if (fee != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${fee.totalFee.toStringAsFixed(fee.spread != null ? 2 : 1)}% fee',
                      style: TextStyle(
                        // Grey out fee for unavailable providers
                        color: !provider.isAvailable
                            ? greyColor
                            : fee.totalFee <= 2.0
                                ? AppTheme.successColor
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: provider.isAvailable && fee.totalFee <= 2.0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (fee.spread != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(incl. ${fee.spread}% spread)',
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(
                                  alpha: provider.isAvailable ? 0.5 : 0.3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (!provider.isAvailable) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      color: greyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _selectProvider(provider),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColorFiltered(
              colorFilter: provider.isAvailable
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0.5,
                      0,
                    ]),
              child: Image.asset(
                provider.imagePath,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .cardColor
                          .withValues(alpha: provider.isAvailable ? 1.0 : 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: provider.isAvailable ? null : greyColor,
                    ),
                  );
                },
              ),
            ),
          ),
          trailing: isSelected
              ? const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: provider.isAvailable ? null : greyColor,
                ),
        ),
      ),
    );
  }
}
