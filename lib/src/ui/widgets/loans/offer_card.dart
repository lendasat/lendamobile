import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/lendasat/models.dart';
import 'package:ark_flutter/src/services/lendasat_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';

/// Card widget displaying a loan offer.
class OfferCard extends StatelessWidget {
  final LoanOffer offer;
  final VoidCallback onTap;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: GlassContainer(
        borderRadius: 16,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with lender and interest
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lender avatar - compact white background
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          offer.lender.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Lender name and verified badge
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              offer.lender.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (offer.lender.vetted) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppTheme.colorBitcoin,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Interest rate highlight
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${offer.interestRatePercent} APY',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Asset flow indicator
                Row(
                  children: [
                    _buildAssetChip(context, 'BTC', isLoan: false),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      ),
                    ),
                    _buildAssetChip(context, offer.loanAssetDisplayName,
                        isLoan: true),
                  ],
                ),
                const SizedBox(height: 16),

                // Details row
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        AppLocalizations.of(context)?.amount ?? 'Amount',
                        offer.loanAmountRange,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        AppLocalizations.of(context)?.duration ?? 'Duration',
                        offer.durationRange,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        AppLocalizations.of(context)?.minLtv ?? 'Min LTV',
                        '${(offer.minLtv * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value,
      {bool highlight = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? Theme.of(context).colorScheme.primary : null,
              ),
        ),
      ],
    );
  }

  Widget _buildAssetChip(BuildContext context, String label,
      {bool isLoan = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = isDarkMode ? AppTheme.white70 : AppTheme.black70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}
