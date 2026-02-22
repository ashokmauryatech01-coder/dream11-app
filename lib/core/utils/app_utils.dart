import 'package:intl/intl.dart';

class AppUtils {
  static String formatMatchDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String getTimeUntilMatch(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) {
      return 'Live';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m left';
    } else {
      return '${difference.inMinutes}m left';
    }
  }
}
