import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';

/// Utility class for launching device app settings.
///
/// Provides platform-specific deep linking to app settings pages
/// where users can manage permissions (camera, notifications, etc.)
class AppSettingsLauncher {
  AppSettingsLauncher._();

  /// Package name used for Android intent URIs
  static const String _androidPackageName = 'com.lendasat.lendamobile';

  /// Opens the app's settings page in device settings.
  ///
  /// - iOS: Opens Settings app directly to app permissions
  /// - Android: Opens app details in system settings
  ///
  /// Shows an error message if the settings cannot be opened.
  static Future<void> openAppSettings(BuildContext context) async {
    // Capture mounted state before async operation
    final navigator = Navigator.of(context, rootNavigator: true);
    final isContextMounted = context.mounted;

    try {
      if (Platform.isIOS) {
        await _openIOSSettings();
      } else if (Platform.isAndroid) {
        await _openAndroidSettings();
      }
    } catch (e) {
      // Only show error if context is still valid
      if (isContextMounted && navigator.context.mounted) {
        _showFallbackError();
      }
    }
  }

  /// Opens iOS app settings using the app-settings: URL scheme
  static Future<void> _openIOSSettings() async {
    final uri = Uri.parse('app-settings:');
    await launchUrl(uri);
  }

  /// Opens Android app settings using intent URI scheme
  static Future<void> _openAndroidSettings() async {
    final uri = Uri.parse(
      'intent:#Intent;'
      'action=android.settings.APPLICATION_DETAILS_SETTINGS;'
      'data=package:$_androidPackageName;'
      'S.browser_fallback_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3D$_androidPackageName;'
      'end',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  /// Shows a fallback error message when settings cannot be opened
  static void _showFallbackError() {
    OverlayService().showError(
      'Please open Settings > Apps > Lendasat > Permissions',
    );
  }
}
