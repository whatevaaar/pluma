extension StringWordCount on String {
  /// Counts words by splitting on whitespace runs.
  /// Returns 0 for empty or whitespace-only strings.
  int get wordCount {
    final trimmed = trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  /// Counts non-whitespace characters.
  int get charCount => replaceAll(RegExp(r'\s'), '').length;

  /// Estimated reading time in minutes, using 200 wpm average.
  /// Returns 1 if the result rounds to 0 to avoid showing "0 min read".
  int get estimatedReadMinutes {
    const wordsPerMinute = 200;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Returns null if the string is empty after trimming, otherwise returns self.
  String? get nullIfEmpty {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
