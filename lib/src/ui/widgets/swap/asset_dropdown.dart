import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/models/swap_token.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A dropdown widget for selecting swap tokens.
/// Similar to Uniswap-style asset selection with search.
class AssetDropdown extends StatelessWidget {
  final SwapToken selectedToken;
  final List<SwapToken> availableTokens;
  final ValueChanged<SwapToken> onTokenSelected;
  final String? label;

  const AssetDropdown({
    super.key,
    required this.selectedToken,
    required this.availableTokens,
    required this.onTokenSelected,
    this.label,
  });

  void _showTokenSelector(BuildContext context) {
    arkBottomSheet(
      context: context,
      child: _TokenSelectorSheet(
        selectedToken: selectedToken,
        availableTokens: availableTokens,
        onTokenSelected: (token) {
          onTokenSelected(token);
          Navigator.pop(context);
        },
        label: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showTokenSelector(context),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(500),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.elementSpacing * 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: AppTheme.elementSpacing * 0.5),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              const SizedBox(width: AppTheme.elementSpacing * 0.5),
              TokenIcon(token: selectedToken, size: AppTheme.cardPadding * 1.25),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for token selection with search
class _TokenSelectorSheet extends StatefulWidget {
  final SwapToken selectedToken;
  final List<SwapToken> availableTokens;
  final ValueChanged<SwapToken> onTokenSelected;
  final String? label;

  const _TokenSelectorSheet({
    required this.selectedToken,
    required this.availableTokens,
    required this.onTokenSelected,
    this.label,
  });

  @override
  State<_TokenSelectorSheet> createState() => _TokenSelectorSheetState();
}

class _TokenSelectorSheetState extends State<_TokenSelectorSheet> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final title = widget.label == 'sell'
        ? 'Select token to sell'
        : widget.label == 'buy'
            ? 'Select token to buy'
            : 'Select token';

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: title,
        hasBackButton: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppTheme.cardPadding * 2),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
            ),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or network...',
                  hintStyle: TextStyle(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding,
                    vertical: AppTheme.elementSpacing,
                  ),
                ),
              ),
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

                return _TokenListItem(
                  token: token,
                  isSelected: isSelected,
                  onTap: () => widget.onTokenSelected(token),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// List item for a token in the selector
class _TokenListItem extends StatelessWidget {
  final SwapToken token;
  final bool isSelected;
  final VoidCallback onTap;

  const _TokenListItem({
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          token.network,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

/// Token icon widget using SVG assets
class TokenIcon extends StatelessWidget {
  final SwapToken token;
  final double size;

  const TokenIcon({
    super.key,
    required this.token,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = _getTokenSvgPath(token);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildFallbackIcon(),
      ),
    );
  }

  /// Get the SVG asset path for a token
  String _getTokenSvgPath(SwapToken token) {
    switch (token) {
      case SwapToken.bitcoin:
        return 'assets/images/tokens/bitcoin.svg';
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return 'assets/images/tokens/usdc.svg';
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return 'assets/images/tokens/usdt.svg';
      case SwapToken.xautEthereum:
        return 'assets/images/tokens/xaut.svg';
    }
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: token.color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        token.icon,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

/// Token icon with network indicator badge using SVG assets
class TokenIconWithNetwork extends StatelessWidget {
  final SwapToken token;
  final double size;

  const TokenIconWithNetwork({
    super.key,
    required this.token,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          TokenIcon(token: token, size: size),
          // Network badge
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: SvgPicture.asset(
                  _getNetworkSvgPath(token),
                  width: size * 0.36,
                  height: size * 0.36,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context) => Container(
                    decoration: BoxDecoration(
                      color: token.networkColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      token.networkIcon,
                      color: Colors.white,
                      size: size * 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the SVG asset path for a network
  String _getNetworkSvgPath(SwapToken token) {
    switch (token) {
      case SwapToken.bitcoin:
        return 'assets/images/tokens/bitcoin.svg';
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return 'assets/images/tokens/polygon.svg';
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return 'assets/images/tokens/eth.svg';
    }
  }
}
