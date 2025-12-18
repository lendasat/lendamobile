import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ark_flutter/src/logger/logger.dart';
// import 'package:http/http.dart' as http; // Uncomment when implementing API
// import 'dart:convert'; // Uncomment when implementing API

/// Service for handling user feedback submission.
///
/// Currently uses mailto: links for email sending.
/// For production, consider implementing a backend API endpoint.
class FeedbackService {
  static const String supportEmail = 'support@lendasat.com';

  // TODO: Add your backend API URL for production
  // static const String feedbackApiUrl = 'https://api.lendasat.com/feedback';

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

  /// Send feedback via backend API (for production use).
  ///
  /// This method sends feedback directly to a backend server which then
  /// sends the email. This approach supports attachments and doesn't
  /// require the user to have an email app configured.
  Future<bool> sendFeedbackViaApi({
    required String feedbackType,
    required String message,
    List<File>? attachments,
    String? deviceInfo,
  }) async {
    // TODO: Implement when backend API is ready
    //
    // Example implementation:
    // try {
    //   final request = http.MultipartRequest('POST', Uri.parse(feedbackApiUrl));
    //   request.fields['type'] = feedbackType;
    //   request.fields['message'] = message;
    //   request.fields['deviceInfo'] = deviceInfo ?? '';
    //
    //   if (attachments != null) {
    //     for (var i = 0; i < attachments.length; i++) {
    //       request.files.add(await http.MultipartFile.fromPath(
    //         'attachment_$i',
    //         attachments[i].path,
    //       ));
    //     }
    //   }
    //
    //   final response = await request.send();
    //   return response.statusCode == 200;
    // } catch (e) {
    //   logger.e('Error sending feedback via API: $e');
    //   return false;
    // }

    logger.w('API feedback not implemented yet, falling back to email');
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
