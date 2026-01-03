import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/screens/swap/swap_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_image_text_button.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
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
      appBar: BitNetAppBar(
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

          // // Action Buttons
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //       children: [
          //         BitNetImageWithTextButton(
          //           AppLocalizations.of(context)!.sendLower,
          //           () {
          //             Navigator.of(context).pushNamed('/send');
          //           },
          //           fallbackIcon: Icons.arrow_upward_rounded,
          //         ),
          //         BitNetImageWithTextButton(
          //           AppLocalizations.of(context)!.receiveLower,
          //           () {
          //             Navigator.of(context).pushNamed('/receive');
          //           },
          //           fallbackIcon: Icons.arrow_downward_rounded,
          //         ),
          //         BitNetImageWithTextButton(
          //           'Swap',
          //           () {
          //             Navigator.push(
          //               context,
          //               MaterialPageRoute(
          //                 builder: (context) => const SwapScreen(),
          //               ),
          //             );
          //           },
          //           fallbackIcon: Icons.sync_rounded,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // const SliverToBoxAdapter(
          //   child: SizedBox(height: 32),
          // ),

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

  Widget _buildInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.aboutBitcoin,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.bitcoinDescription,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
