class TimeUtils {
  static String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

  static String formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return _plural((difference.inDays / 365).floor(), 'Year');
      } else if (difference.inDays > 30) {
        return _plural((difference.inDays / 30).floor(), 'Month');
      } else if (difference.inDays > 0) {
        return _plural(difference.inDays, 'Day');
      } else if (difference.inHours > 0) {
        return _plural(difference.inHours, 'Hour');
      } else if (difference.inMinutes > 0) {
        return _plural(difference.inMinutes, 'Minute');
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}

// Keep backward compatibility
String formatTimeAgo(String dateString) {
  return TimeUtils.formatTimeAgo(dateString);
}
