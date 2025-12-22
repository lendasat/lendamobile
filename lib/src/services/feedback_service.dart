import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ark_flutter/src/logger/logger.dart';

/// Service for handling user feedback submission.
///
/// Currently uses mailto: links for email sending.
class FeedbackService {
  static const String supportEmail = 'support@lendasat.com';

  /// Send feedback via email using the device's email client.
  ///
  /// This is the simplest approach but has limitations:
  /// - Attachments may not work on all platforms via mailto
  /// - User needs a configured email app
  Future<bool> sendFeedbackViaEmail({
    required String feedbackType,
    required String message,
    String? deviceInfo,
  }) async {
    try {
      final subject = Uri.encodeComponent('[$feedbackType] Lenda App Feedback');
      final body = Uri.encodeComponent(
        '$message\n\n---\nDevice Info:\n${deviceInfo ?? "Not available"}',
      );

      final mailtoUri = Uri.parse(
        'mailto:$supportEmail?subject=$subject&body=$body',
      );

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        return true;
      } else {
        logger.e('Could not launch email client');
        return false;
      }
    } catch (e) {
      logger.e('Error sending feedback via email: $e');
      return false;
    }
  }

  /// Send feedback via backend API.
  /// Currently falls back to email - API can be implemented when needed.
  Future<bool> sendFeedbackViaApi({
    required String feedbackType,
    required String message,
    List<File>? attachments,
    String? deviceInfo,
  }) async {
    // Fall back to email for now
    return sendFeedbackViaEmail(
      feedbackType: feedbackType,
      message: message,
      deviceInfo: deviceInfo,
    );
  }

  /// Get device information for debugging purposes.
  String getDeviceInfo() {
    final buffer = StringBuffer();
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('OS Version: ${Platform.operatingSystemVersion}');
    buffer.writeln('Dart Version: ${Platform.version}');
    if (!kReleaseMode) {
      buffer.writeln('Mode: Debug');
    } else {
      buffer.writeln('Mode: Release');
    }
    return buffer.toString();
  }
}
