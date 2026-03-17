class DateFormatter {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Returns a human-readable relative time string.
  /// Examples: "just now", "2m ago", "1h ago", "yesterday", "Mar 15"
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(dtDay).inDays;

    if (dayDiff == 1) return 'yesterday';

    return '${_months[dt.month - 1]} ${dt.day}';
  }

  /// Returns a full date-time string.
  /// Example: "Mar 15, 2026 10:32 AM"
  static String formatFull(DateTime dt) {
    final month = _months[dt.month - 1];
    final time = formatTime(dt);
    return '$month ${dt.day}, ${dt.year} $time';
  }

  /// Returns a time-only string.
  /// Example: "10:32 AM"
  static String formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Returns a human-readable duration string.
  /// Examples: "1h 23m", "45s"
  static String formatDuration(Duration d) {
    if (d.inHours > 0) {
      final minutes = d.inMinutes.remainder(60);
      return '${d.inHours}h ${minutes}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m';
    }
    return '${d.inSeconds}s';
  }
}
