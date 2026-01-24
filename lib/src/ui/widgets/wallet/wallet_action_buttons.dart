import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_image_text_button.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Action buttons row for wallet screen (Send, Receive, Scan, Buy)
class WalletActionButtons extends StatelessWidget {
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onScan;
  // final VoidCallback onBuy;

  const WalletActionButtons({
    super.key,
    required this.onSend,
    required this.onReceive,
    required this.onScan,
    // required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Row(
        children: [
          Expanded(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.send ?? "Send",
              onSend,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_upward_rounded,
            ),
          ),
          Expanded(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.receive ?? "Receive",
              onReceive,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.arrow_downward_rounded,
            ),
          ),
          // Scan button
          Expanded(
            child: BitNetImageWithTextButton(
              AppLocalizations.of(context)?.scan ?? "Scan",
              onScan,
              width: AppTheme.cardPadding * 2.5,
              height: AppTheme.cardPadding * 2.5,
              fallbackIcon: Icons.qr_code_scanner_rounded,
            ),
          ),
          // Buy button - temporarily disabled
          // Flexible(
          //   child: BitNetImageWithTextButton(
          //     "Buy",
          //     onBuy,
          //     width: AppTheme.cardPadding * 2.5,
          //     height: AppTheme.cardPadding * 2.5,
          //     fallbackIcon: FontAwesomeIcons.btc,
          //     fallbackIconSize: AppTheme.iconSize * 1.5,
          //   ),
          // ),
        ],
      ),
    );
  }
}
