import 'package:pluma/features/statistics/domain/daily_stats.dart';

abstract interface class StatisticsRepository {
  /// Reactive stream of the full writing stats aggregate.
  Stream<WritingStats> watchStats();

  /// Upserts daily stats for today and inserts a WritingSession row.
  /// Called at the end of each writing session.
  Future<void> recordSession({
    required String documentId,
    required int wordsDelta,
    required int durationSeconds,
    DateTime? startedAt,
  });

  /// Returns heatmap data for the last [days] days.
  /// Kept separate from watchStats() to avoid recomputing on every stream event.
  Future<Map<String, int>> getHeatmapData({int days = 365});
}
