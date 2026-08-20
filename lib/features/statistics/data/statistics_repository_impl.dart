import 'package:flutter/foundation.dart';
import 'package:pluma/core/constants/app_constants.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/core/extensions/datetime_ext.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';
import 'package:pluma/features/statistics/data/statistics_dao.dart';
import 'package:pluma/features/statistics/domain/daily_stats.dart';
import 'package:pluma/features/statistics/domain/statistics_repository.dart';
import 'package:pluma/features/statistics/domain/streak_calculator.dart' as streak;
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

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
        heatmapData: {for (final r in rows) r.date: r.wordsWritten},
      );
    });
  }

  @override
  Future<void> recordSession({
    required String documentId,
    required int wordsDelta,
    required int durationSeconds,
    DateTime? startedAt,
  }) async {
    if (wordsDelta <= 0 && durationSeconds < 30) return;
    final words = wordsDelta < 0 ? 0 : wordsDelta;
    final dateKey = DateTime.now().toDateKey;
    final minutes = (durationSeconds / 60).ceil();
    final start = startedAt ??
        DateTime.now().subtract(Duration(seconds: durationSeconds));

    // upsertToday must always succeed — it drives the statistics screen.
    // insertSession is best-effort: a failure there must not prevent the
    // daily snapshot from being written (and Drift's stream from being
    // notified). Run sequentially so that upsertToday commits first.
    await _dao.upsertToday(
      dateKey: dateKey,
      wordsDelta: words,
      minutes: minutes,
    );
    try {
      await _dao.insertSession(
        WritingSessionsCompanion.insert(
          id: const Uuid().v4(),
          documentId: documentId,
          wordsWritten: Value(words),
          durationSeconds: Value(durationSeconds),
          startedAt: start,
          endedAt: Value(DateTime.now()),
        ),
      );
    } on Object catch (e, st) {
      // Log but don't rethrow: the daily snapshot was already committed.
      debugPrint('[StatisticsRepo] insertSession failed (non-fatal): $e\n$st');
    }
  }

  @override
  Future<Map<String, int>> getHeatmapData({int days = 365}) async {
    final to = DateTime.now().toDateKey;
    final from = DateTime.now().subtract(Duration(days: days)).toDateKey;
    final rows = await _dao.getRange(from, to);
    return {for (final r in rows) r.date: r.wordsWritten};
  }
}

@riverpod
StatisticsRepository statisticsRepository(Ref ref) {
  final dao = ref.watch(statisticsDaoProvider);
  final dailyTarget = ref.watch(settingsProvider).value?.dailyWordTarget ??
      AppConstants.defaultDailyWordTarget;
  return StatisticsRepositoryImpl(dao, dailyTarget);
}
