import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// A utility class for formatting dates in the application
class DateFormatter {
  /// Formats a DateTime object to a readable string format
  /// Default format is 'dd/MM/yyyy'
  static String formatDate(DateTime dateTime, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(dateTime);
  }
  
  /// Formats a DateTime object to include time
  /// Format: 'dd/MM/yyyy HH:mm'
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  /// Formats a DateTime to a relative time string (e.g., "2 days ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${'years_ago'.tr}';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${'months_ago'.tr}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${'days_ago'.tr}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${'hours_ago'.tr}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${'minutes_ago'.tr}';
    } else {
      return 'just_now'.tr;
    }
  }
}
