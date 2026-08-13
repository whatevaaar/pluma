import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';

part 'statistics_dao.g.dart';

@DriftAccessor(tables: [DailyStats, WritingSessions])
class StatisticsDao extends DatabaseAccessor<AppDatabase>
    with _$StatisticsDaoMixin {
  StatisticsDao(super.db);

  // Streams

  Stream<List<DailyStat>> watchAll() {
    return (select(dailyStats)
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Stream<DailyStat?> watchToday(String todayKey) {
    return (select(dailyStats)..where((s) => s.date.equals(todayKey)))
        .watchSingleOrNull();
  }

  // Queries

  Future<List<DailyStat>> getRange(String from, String to) {
    return (select(dailyStats)
          ..where((s) => s.date.isBetweenValues(from, to))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
  }

  Future<int> getTotalWords() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(words_written), 0) AS total FROM daily_stats',
      readsFrom: {dailyStats},
    ).getSingle();
    return result.data['total'] as int;
  }

  Future<int> getTotalDaysActive() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS count FROM daily_stats WHERE words_written > 0',
      readsFrom: {dailyStats},
    ).getSingle();
    return result.data['count'] as int;
  }

  Future<int> getBestDay() async {
    final result = await customSelect(
      'SELECT COALESCE(MAX(words_written), 0) AS best FROM daily_stats',
      readsFrom: {dailyStats},
    ).getSingle();
    return result.data['best'] as int;
  }

  Future<int> getBestSession() async {
    final result = await customSelect(
      'SELECT COALESCE(MAX(words_written), 0) AS best FROM writing_sessions',
      readsFrom: {writingSessions},
    ).getSingle();
    return result.data['best'] as int;
  }

  // Upsert: adds [wordsDelta] and [minutes] to today's snapshot.
  Future<void> upsertToday({
    required String dateKey,
    required int wordsDelta,
    required int minutes,
  }) async {
    await customStatement('''
      INSERT INTO daily_stats (date, words_written, minutes_written, sessions_count)
      VALUES (?, ?, ?, 1)
      ON CONFLICT(date) DO UPDATE SET
        words_written = words_written + ?,
        minutes_written = minutes_written + ?,
        sessions_count = sessions_count + 1
    ''', [dateKey, wordsDelta, minutes, wordsDelta, minutes]);
  }

  // Sessions

  Future<void> insertSession(WritingSessionsCompanion companion) {
    return into(writingSessions).insert(companion);
  }

  Future<void> updateSession(WritingSessionsCompanion companion) {
    return (update(writingSessions)
          ..where((s) => s.id.equals(companion.id.value)))
        .write(companion);
  }
}

@riverpod
StatisticsDao statisticsDao(Ref ref) => ref.watch(appDatabaseProvider).statisticsDao;
