import 'package:flutter/material.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/utils/app_settings_launcher.dart';

/// Content widget for the camera permission request bottom sheet.
///
/// Displays a friendly message explaining why camera access is needed
/// and provides buttons to cancel or open device settings.
class CameraPermissionSheetContent extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onGrantAccess;

  const CameraPermissionSheetContent({
    super.key,
    this.onCancel,
    this.onGrantAccess,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.cardPadding * 1.5,
        vertical: AppTheme.cardPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppTheme.elementSpacing),
          _buildBaniImage(),
          const SizedBox(height: AppTheme.cardPadding * 1.5),
          _buildTitle(context),
          const SizedBox(height: AppTheme.elementSpacing),
          _buildDescription(isDarkMode),
          const Spacer(),
          _buildButtons(context),
          const SizedBox(height: AppTheme.elementSpacing),
        ],
      ),
    );
  }

  Widget _buildBaniImage() {
    return SizedBox(
      height: 140,
      child: Image.asset(
        'assets/images/bani/bani_shocked.png',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      "Camera Access Required",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(bool isDarkMode) {
    return Text(
      'To scan QR codes, we need permission to use your camera. '
      'Please enable it in your device settings.',
      style: TextStyle(
        color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
        fontSize: 15,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LongButtonWidget(
            title: 'Cancel',
            buttonType: ButtonType.secondary,
            onTap: onCancel ?? () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: AppTheme.elementSpacing),
        Expanded(
          child: LongButtonWidget(
            title: 'Open Settings',
            buttonType: ButtonType.solid,
            onTap: onGrantAccess ??
                () {
                  Navigator.of(context).pop();
                  AppSettingsLauncher.openAppSettings(context);
                },
          ),
        ),
      ],
    );
  }
}

/// Shows the camera permission request bottom sheet.
///
/// Returns a Future that completes when the bottom sheet is dismissed.
/// The [onGrantAccess] callback is called when the user taps "Grant Access".
Future<void> showCameraPermissionSheet({
  required BuildContext context,
  VoidCallback? onGrantAccess,
}) async {
  final screenHeight = MediaQuery.of(context).size.height;

  await arkBottomSheet(
    context: context,
    height: screenHeight * 0.65,
    isDismissible: true,
    child: CameraPermissionSheetContent(
      onCancel: () => Navigator.of(context).pop(),
      onGrantAccess: () {
        Navigator.of(context).pop();
        if (onGrantAccess != null) {
          onGrantAccess();
        } else {
          AppSettingsLauncher.openAppSettings(context);
        }
      },
    ),
  );
}
