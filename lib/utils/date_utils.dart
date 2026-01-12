
import 'package:intl/intl.dart';

/// Utility class for date operations
class AppDateUtils {
  /// Format date to string
  static String formatDate(DateTime date, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  /// Get relative time string
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(date);
    }
  }
}
