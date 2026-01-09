import 'package:intl/intl.dart';

/// Centralized date formatting utilities for consistent date display across the app.
class DateFormatter {
  DateFormatter._();

  /// Formats a timestamp for display in transaction lists.
  /// - Today: shows time (e.g., "14:30")
  /// - Yesterday: shows "Yesterday"
  /// - Last 7 days: shows weekday (e.g., "Mon", "Tue")
  /// - Older: shows date (e.g., "5/1/2026")
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return DateFormat('HH:mm').format(date);
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE').format(date); // Mon, Tue, etc.
    } else {
      return DateFormat('d/M/y').format(date);
    }
  }

  /// Formats a Unix timestamp (seconds) for display in transaction lists.
  static String formatRelativeDateFromTimestamp(int timestampSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    return formatRelativeDate(date);
  }

  /// Formats a time ago string (e.g., "5m ago", "2h ago", "3d ago").
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // If date is in the future, return empty string to avoid "just now" forever bug
    if (difference.isNegative) {
      return '';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Formats a Unix timestamp (seconds) as time ago string.
  static String formatTimeAgoFromTimestamp(int timestampSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    return formatTimeAgo(date);
  }

  /// Formats a full date with time (e.g., "2026-01-05 14:30").
  static String formatFullDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  /// Formats a full date with time from Unix timestamp (seconds).
  static String formatFullDateTimeFromTimestamp(int timestampSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    return formatFullDateTime(date);
  }
}
