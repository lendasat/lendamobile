import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Header for block details, showing block information and actions
class BlockHeader extends StatelessWidget {
  final String blockHeight;
  final String blockId;
  final VoidCallback onClose;
  final VoidCallback? onCopied;

  const BlockHeader({
    super.key,
    required this.blockHeight,
    required this.blockId,
    required this.onClose,
    this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppTheme.cardPadding,
          bottom: AppTheme.elementSpacing,
        ),
        child: Row(
          children: [
            // Block title and height
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.block,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  ' $blockHeight',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: AppTheme.colorBitcoin,
                      ),
                ),
              ],
            ),

            const Spacer(),

            // Block ID and copy action
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: blockId));
                    onCopied?.call();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy,
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppTheme.black60
                            : AppTheme.white60,
                        size: AppTheme.elementSpacing * 1.5,
                      ),
                      const SizedBox(width: AppTheme.elementSpacing / 2),
                      Text(
                        '${blockId.substring(0, 5)}...${blockId.substring(blockId.length - 5)}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.elementSpacing / 2),

                // Close button
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
