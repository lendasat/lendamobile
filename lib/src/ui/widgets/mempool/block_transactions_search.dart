import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:flutter/material.dart';

/// Search field for block transactions that displays transaction count
/// This widget acts as a button that navigates to the BlockTransactions screen
class BlockTransactionsSearch extends StatelessWidget {
  final int transactionCount;
  final Function(String) handleSearch;
  final VoidCallback onTap;
  final bool isEnabled;

  const BlockTransactionsSearch({
    super.key,
    required this.transactionCount,
    required this.handleSearch,
    required this.onTap,
    this.isEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    

    // This widget is designed to be a navigation button, not an actual search field
    // Tapping navigates to BlockTransactions screen where real search happens
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            height: AppTheme.paddingL * 1.75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.search,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Text(
                  '$transactionCount transactions',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
