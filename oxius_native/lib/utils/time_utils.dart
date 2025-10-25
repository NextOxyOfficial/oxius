class TimeUtils {
  static String formatTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '${years}y';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '${months}mo';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
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
