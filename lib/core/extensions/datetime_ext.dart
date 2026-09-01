const List<String> _spanishMonthsAbbr = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

extension DateTimeExt on DateTime {
  /// Returns true if this date falls on the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns true if this date is today (local time).
  bool get isToday => isSameDay(DateTime.now());

  /// Returns true if this date was yesterday (local time).
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Returns a "YYYY-MM-DD" key suitable for DailyStats and heatmap data.
  String get toDateKey {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Strips the time component, returning midnight of the same day.
  DateTime get dateOnly => DateTime(year, month, day);

  /// "21 ago 2026" — a Spanish medium date, matching the app's Spanish UI
  /// (instead of a locale-dependent or bare numeric format).
  String toSpanishMediumDate() =>
      '$day ${_spanishMonthsAbbr[month - 1]} $year';

  /// "Hoy" / "Ayer" / "21 ago 2026" — the app's relative day label.
  String toRelativeSpanishDate() {
    if (isToday) return 'Hoy';
    if (isYesterday) return 'Ayer';
    return toSpanishMediumDate();
  }
}
