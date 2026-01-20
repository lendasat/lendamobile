import 'package:flutter/cupertino.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';

/// Bottom control bar for the QR scanner screen.
///
/// Provides buttons for:
/// - Switching between front/back camera
/// - Toggling flashlight/torch
/// - Picking image from gallery
class QrScannerControls extends StatelessWidget {
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleTorch;
  final VoidCallback onPickImage;
  final bool isTorchEnabled;

  const QrScannerControls({
    super.key,
    required this.onSwitchCamera,
    required this.onToggleTorch,
    required this.onPickImage,
    this.isTorchEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppTheme.cardPadding * 8,
        ),
        child: GlassContainer(
          width: AppTheme.cardPadding * 6.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.elementSpacing * 1.5,
              vertical: AppTheme.elementSpacing / 1.25,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildControlButton(
                  icon: CupertinoIcons.switch_camera,
                  onTap: onSwitchCamera,
                ),
                _buildControlButton(
                  icon: isTorchEnabled
                      ? CupertinoIcons.bolt_fill
                      : CupertinoIcons.bolt_slash_fill,
                  onTap: onToggleTorch,
                  color: isTorchEnabled ? AppTheme.colorBitcoin : AppTheme.white90,
                ),
                _buildControlButton(
                  icon: CupertinoIcons.photo_fill,
                  onTap: onPickImage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color),
    );
  }
}
