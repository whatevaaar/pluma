import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_stats.freezed.dart';

@freezed
class DailyStats with _$DailyStats {
  const factory DailyStats({
    required String date, // "YYYY-MM-DD"
    required int wordsWritten,
    required int minutesWritten,
    required int sessionsCount,
  }) = _DailyStats;
}

@freezed
class WritingStats with _$WritingStats {
  const factory WritingStats({
    required int totalWords,
    required int currentStreak,
    required int longestStreak,
    required int dailyWordCount,
    required int dailyTarget,
    required int todaySessions,
    required int totalDaysActive,
    required int bestDay,         // highest word count in a single day
    required int bestSession,     // highest word count in a single session
    required int averageDaily,    // rolling average over active days
    // "YYYY-MM-DD" → words — last 365 days for heatmap
    required Map<String, int> heatmapData,
  }) = _WritingStats;

  const WritingStats._();

  /// Completion ratio toward daily target, 0.0–1.0.
  double get dailyCompletionRatio {
    if (dailyTarget <= 0) return 0.0;
    return (dailyWordCount / dailyTarget).clamp(0.0, 1.0);
  }

  bool get dailyTargetReached => dailyWordCount >= dailyTarget && dailyTarget > 0;

  static WritingStats empty(int dailyTarget) => WritingStats(
        totalWords: 0,
        currentStreak: 0,
        longestStreak: 0,
        dailyWordCount: 0,
        dailyTarget: dailyTarget,
        todaySessions: 0,
        totalDaysActive: 0,
        bestDay: 0,
        bestSession: 0,
        averageDaily: 0,
        heatmapData: {},
      );
}
