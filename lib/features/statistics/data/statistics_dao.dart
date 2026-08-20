import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistics_dao.g.dart';

@DriftAccessor(tables: [DailyStats, WritingSessions])
class StatisticsDao extends DatabaseAccessor<AppDatabase>
    with _$StatisticsDaoMixin {
  StatisticsDao(super.attachedDatabase);

  // Streams

  Stream<List<DailyStat>> watchAll() {
    return (select(dailyStats)
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  // Queries

  Future<List<DailyStat>> getRange(String from, String to) {
    return (select(dailyStats)
          ..where((s) => s.date.isBetweenValues(from, to))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
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
  //
  // Uses customUpdate (not customStatement) so Drift's reactive infrastructure
  // is notified of the table change and watchAll() re-emits.
  Future<void> upsertToday({
    required String dateKey,
    required int wordsDelta,
    required int minutes,
  }) async {
    await customUpdate(
      '''
      INSERT INTO daily_stats (date, words_written, minutes_written, sessions_count)
      VALUES (?, ?, ?, 1)
      ON CONFLICT(date) DO UPDATE SET
        words_written = words_written + ?,
        minutes_written = minutes_written + ?,
        sessions_count = sessions_count + 1
      ''',
      variables: [
        Variable.withString(dateKey),
        Variable.withInt(wordsDelta),
        Variable.withInt(minutes),
        Variable.withInt(wordsDelta),
        Variable.withInt(minutes),
      ],
      updates: {dailyStats},
      updateKind: UpdateKind.insert,
    );
  }

  // Sessions

  Future<void> insertSession(WritingSessionsCompanion companion) {
    return into(writingSessions).insert(companion);
  }

}

@riverpod
StatisticsDao statisticsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).statisticsDao;
