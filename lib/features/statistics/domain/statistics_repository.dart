import 'package:pluma/features/statistics/domain/daily_stats.dart';

abstract interface class StatisticsRepository {
  /// Reactive stream of the full writing stats aggregate.
  Stream<WritingStats> watchStats();

  /// Upserts daily stats for today. Called at the end of each writing session.
  ///
  /// [wordsDelta] is the number of words added (or removed, if negative) in
  /// this session — NOT the document's total. Preserves the count of words
  /// written even when the user deletes text.
  Future<void> recordSession({
    required int wordsDelta,
    required int durationSeconds,
  });

  /// Returns heatmap data for the last [days] days.
  Future<Map<String, int>> getHeatmapData({int days = 365});

  /// Returns the streak current value computed from DailyStats rows.
  Future<int> computeCurrentStreak();

  /// Returns the longest streak ever recorded.
  Future<int> computeLongestStreak();

  /// Returns the best single-day word count.
  Future<int> computeBestDay();

  /// Returns the best single-session word count.
  Future<int> computeBestSession();
}
