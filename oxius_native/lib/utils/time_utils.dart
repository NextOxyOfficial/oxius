class TimeUtils {
  static String formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years Year';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months Month';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} Day';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} Hour';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} Minute';
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
