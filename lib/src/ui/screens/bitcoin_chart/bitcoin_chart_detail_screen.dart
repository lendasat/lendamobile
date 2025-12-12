import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_image_text_button.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

class BitcoinChartDetailScreen extends StatefulWidget {
  const BitcoinChartDetailScreen({super.key});

  @override
  State<BitcoinChartDetailScreen> createState() =>
      _BitcoinChartDetailScreenState();
}

class _BitcoinChartDetailScreenState extends State<BitcoinChartDetailScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: AppLocalizations.of(context)!.bitcoinPriceChart,
        onTap: () => Navigator.of(context).pop(),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Spacer for AppBar
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),

          // Chart Section
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: BitcoinChartCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  BitNetImageWithTextButton(
                    AppLocalizations.of(context)!.sendLower,
                    () {
                      Navigator.of(context).pushNamed('/send');
                    },
                    fallbackIcon: Icons.arrow_upward_rounded,
                  ),
                  BitNetImageWithTextButton(
                    AppLocalizations.of(context)!.receiveLower,
                    () {
                      Navigator.of(context).pushNamed('/receive');
                    },
                    fallbackIcon: Icons.arrow_downward_rounded,
                  ),
                  BitNetImageWithTextButton(
                    'Swap',
                    () {
                      // Swap functionality
                    },
                    fallbackIcon: Icons.sync_rounded,
                  ),
                  BitNetImageWithTextButton(
                    'Buy',
                    () {
                      Navigator.of(context).pushNamed('/buy');
                    },
                    fallbackIcon: Icons.currency_bitcoin,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),

          // Cryptos Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cryptos',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bitcoin Onchain
                  _buildCryptoItem(
                    context,
                    'Bitcoin (Onchain)',
                    'BTC',
                    'assets/images/bitcoin.png',
                  ),
                  const SizedBox(height: 12),
                  // Bitcoin Lightning
                  _buildCryptoItem(
                    context,
                    'Bitcoin (Lightning)',
                    'BTC',
                    'assets/images/bitcoin.png',
                    isLightning: true,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),

          // About Section
          SliverToBoxAdapter(
            child: _buildInfoCard(context),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoItem(
    BuildContext context,
    String name,
    String symbol,
    String imagePath, {
    bool isLightning = false,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 12.0,
      opacity: 0.1,
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: isLightning
                  ? const Icon(
                      Icons.bolt,
                      color: AppTheme.colorBitcoin,
                      size: 32,
                    )
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and symbol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  symbol,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Arrow
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    // Plain text section without box - matches BitnetGithub style
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.aboutBitcoinPriceData,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.thePriceDataShown,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            AppLocalizations.of(context)!.dataSource,
            AppLocalizations.of(context)!.liveBitcoinMarketData,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            AppLocalizations.of(context)!.currency,
            'USD',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context,
            AppLocalizations.of(context)!.updateFrequency,
            AppLocalizations.of(context)!.realTime,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
