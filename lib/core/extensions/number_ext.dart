extension IntWordFormat on int {
  /// "1.5k pal." / "450 pal." — used in document tiles.
  String formatAsWordCount() {
    if (this >= 1000) {
      final k = this / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k pal.';
    }
    return '$this pal.';
  }

  /// "1.5k palabras" / "450 palabras" — used in stats screens.
  String formatAsWords() {
    if (this >= 1000) {
      final k = this / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k palabras';
    }
    return '$this palabras';
  }
}
