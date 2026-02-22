import 'package:intl/intl.dart';

class AppUtils {
  static String formatMatchDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String getTimeUntilMatch(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Started';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Starting now';
    }
  }

  static String formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    return '₹${amount.toString()}';
  }

  static String formatPoints(dynamic points) {
    if (points == null) return '0';
    return points.toString();
  }
}
