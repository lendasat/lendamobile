import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';

/// Utility class for launching device app settings.
///
/// Provides platform-specific deep linking to app settings pages
/// where users can manage permissions (camera, notifications, etc.)
class AppSettingsLauncher {
  AppSettingsLauncher._();

  /// Opens the app's settings page in device settings.
  ///
  /// - iOS: Opens Settings app directly to app permissions
  /// - Android: Opens app details in system settings
  ///
  /// Shows an error message if the settings cannot be opened.
  static Future<void> openAppSettings(BuildContext context) async {
    try {
      if (Platform.isIOS) {
        await _openIOSSettings();
      } else if (Platform.isAndroid) {
        await _openAndroidSettings();
      }
    } catch (e) {
      _showFallbackError();
    }
  }

  /// Opens iOS app settings using the app-settings: URL scheme
  static Future<void> _openIOSSettings() async {
    final uri = Uri.parse('app-settings:');
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    } else {
      _showFallbackError();
    }
  }

  /// Opens Android app settings using the app_settings package
  static Future<void> _openAndroidSettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (_) {
      _showFallbackError();
    }
  }

  /// Shows a fallback error message when settings cannot be opened
  static void _showFallbackError() {
    OverlayService().showError(
      'Please open Settings > Apps > Lendasat > Permissions',
    );
  }
}
