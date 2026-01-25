import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/swap/asset_dropdown.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for token selection with search
class TokenSelectorSheet extends StatefulWidget {
  final SwapToken selectedToken;
  final List<SwapToken> availableTokens;
  final ValueChanged<SwapToken> onTokenSelected;
  final String? label;

  const TokenSelectorSheet({
    super.key,
    required this.selectedToken,
    required this.availableTokens,
    required this.onTokenSelected,
    this.label,
  });

  @override
  State<TokenSelectorSheet> createState() => _TokenSelectorSheetState();
}

class _TokenSelectorSheetState extends State<TokenSelectorSheet> {
  String _searchQuery = '';

  List<SwapToken> get _filteredTokens {
    if (_searchQuery.isEmpty) {
      return widget.availableTokens;
    }
    final query = _searchQuery.toLowerCase();
    return widget.availableTokens.where((token) {
      return token.symbol.toLowerCase().contains(query) ||
          token.network.toLowerCase().contains(query) ||
          token.displayName.toLowerCase().contains(query) ||
          token.tokenId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.label == 'sell'
        ? 'Select token to sell'
        : widget.label == 'buy'
            ? 'Select token to buy'
            : 'Select token';

    return ArkScaffoldUnsafe(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: title,
        hasBackButton: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            const SizedBox(height: AppTheme.cardPadding * 3),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
              ),
              child: SearchFieldWidget(
                hintText: 'Search tokens...',
                isSearchEnabled: true,
                handleSearch: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Token list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.cardPadding,
                ),
                itemCount: _filteredTokens.length,
                itemBuilder: (context, index) {
                  final token = _filteredTokens[index];
                  final isSelected = token == widget.selectedToken;

                  return TokenListItem(
                    token: token,
                    isSelected: isSelected,
                    onTap: () => widget.onTokenSelected(token),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List item for a token in the selector
class TokenListItem extends StatelessWidget {
  final SwapToken token;
  final bool isSelected;
  final VoidCallback onTap;

  const TokenListItem({
    super.key,
    required this.token,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing * 0.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
            opacity: isSelected ? 0.3 : 0.15,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.elementSpacing),
              child: Row(
                children: [
                  // Token icon with network badge
                  TokenIconWithNetwork(token: token, size: 44),
                  const SizedBox(width: AppTheme.elementSpacing),
                  // Token info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.symbol,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          token.network,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDarkMode
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Selected indicator
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.successColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
