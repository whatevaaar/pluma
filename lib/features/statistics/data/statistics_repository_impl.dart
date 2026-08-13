import 'package:pluma/core/extensions/datetime_ext.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';
import 'package:pluma/features/statistics/data/statistics_dao.dart';
import 'package:pluma/features/statistics/domain/daily_stats.dart';
import 'package:pluma/features/statistics/domain/statistics_repository.dart';
import 'package:pluma/features/statistics/domain/streak_calculator.dart' as streak;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistics_repository_impl.g.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  StatisticsRepositoryImpl(this._dao, this._dailyTarget);

  final StatisticsDao _dao;
  final int _dailyTarget;

  @override
  Stream<WritingStats> watchStats() {
    return _dao.watchAll().asyncMap((rows) async {
      final bestDay = await _dao.getBestDay();
      final bestSession = await _dao.getBestSession();
      final todayKey = DateTime.now().toDateKey;
      final todayRow = rows.where((r) => r.date == todayKey).firstOrNull;

      final activeDates = rows
          .where((r) => r.wordsWritten > 0)
          .map((r) => r.date)
          .toList();

      final currentStreak = streak.computeCurrentStreak(activeDates, todayKey);
      final longestStreak = streak.computeLongestStreak(activeDates);

      final cutoffKey = DateTime.now()
          .subtract(const Duration(days: 365))
          .toDateKey;
      final heatmap = <String, int>{
        for (final r in rows)
          if (r.date.compareTo(cutoffKey) >= 0) r.date: r.wordsWritten,
      };

      final totalWords = rows.fold(0, (sum, r) => sum + r.wordsWritten);
      final totalDaysActive = activeDates.length;
      final averageDaily =
          totalDaysActive > 0 ? totalWords ~/ totalDaysActive : 0;

      return WritingStats(
        totalWords: totalWords,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        dailyWordCount: todayRow?.wordsWritten ?? 0,
        dailyTarget: _dailyTarget,
        todaySessions: todayRow?.sessionsCount ?? 0,
        totalDaysActive: totalDaysActive,
        bestDay: bestDay,
        bestSession: bestSession,
        averageDaily: averageDaily,
        heatmapData: heatmap,
      );
    });
  }

  @override
  Future<void> recordSession({
    required int wordsDelta,
    required int durationSeconds,
  }) async {
    if (wordsDelta <= 0 && durationSeconds < 30) return;
    final dateKey = DateTime.now().toDateKey;
    final minutes = (durationSeconds / 60).ceil().clamp(0, durationSeconds);
    await _dao.upsertToday(
      dateKey: dateKey,
      wordsDelta: wordsDelta.clamp(0, wordsDelta),
      minutes: minutes,
    );
  }

  @override
  Future<Map<String, int>> getHeatmapData({int days = 365}) async {
    final to = DateTime.now().toDateKey;
    final from = DateTime.now().subtract(Duration(days: days)).toDateKey;
    final rows = await _dao.getRange(from, to);
    return {for (final r in rows) r.date: r.wordsWritten};
  }

  @override
  Future<int> computeCurrentStreak() async {
    final rows = await _dao.getRange('0000-01-01', DateTime.now().toDateKey);
    final active = rows.where((r) => r.wordsWritten > 0).map((r) => r.date).toList();
    return streak.computeCurrentStreak(active, DateTime.now().toDateKey);
  }

  @override
  Future<int> computeLongestStreak() async {
    final rows = await _dao.getRange('0000-01-01', DateTime.now().toDateKey);
    final active = rows.where((r) => r.wordsWritten > 0).map((r) => r.date).toList();
    return streak.computeLongestStreak(active);
  }

  @override
  Future<int> computeBestDay() => _dao.getBestDay();

  @override
  Future<int> computeBestSession() => _dao.getBestSession();
}

@riverpod
StatisticsRepository statisticsRepository(Ref ref) {
  final dao = ref.watch(statisticsDaoProvider);
  final dailyTarget =
      ref.watch(settingsProvider).value?.dailyWordTarget ?? 500;
  return StatisticsRepositoryImpl(dao, dailyTarget);
}
