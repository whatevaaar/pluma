import 'package:pluma/core/extensions/datetime_ext.dart';

/// Returns the current streak: consecutive active days ending today or yesterday.
/// Implements "grace period" — if today has no activity but yesterday does,
/// the streak is still alive.
int computeCurrentStreak(List<String> activeDates, String today) {
  if (activeDates.isEmpty) return 0;
  final sorted = [...activeDates]..sort((a, b) => b.compareTo(a));
  var cursor = today;
  if (!sorted.contains(today)) {
    final yesterday =
        DateTime.parse(today).subtract(const Duration(days: 1)).toDateKey;
    if (!sorted.contains(yesterday)) return 0;
    cursor = yesterday;
  }
  var streak = 0;
  for (final date in sorted) {
    if (date == cursor) {
      streak++;
      cursor = DateTime.parse(cursor)
          .subtract(const Duration(days: 1))
          .toDateKey;
    } else {
      break;
    }
  }
  return streak;
}

/// Returns the longest streak ever recorded across all history.
int computeLongestStreak(List<String> activeDates) {
  if (activeDates.isEmpty) return 0;
  final sorted = [...activeDates]..sort();
  var longest = 1;
  var current = 1;
  for (var i = 1; i < sorted.length; i++) {
    final prev = DateTime.parse(sorted[i - 1]);
    final curr = DateTime.parse(sorted[i]);
    if (curr.difference(prev).inDays == 1) {
      current++;
      if (current > longest) longest = current;
    } else {
      current = 1;
    }
  }
  return longest;
}
