import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/statistics/data/statistics_repository_impl.dart';
import 'package:pluma/features/statistics/presentation/statistics_notifier.dart';

import '../../../shared/fakes/fake_statistics_repository.dart';

ProviderContainer _makeContainer(FakeStatisticsRepository fake) {
  return ProviderContainer(
    overrides: [statisticsRepositoryProvider.overrideWithValue(fake)],
  );
}

void main() {
  group('StatisticsNotifier', () {
    test('initializes with empty stats', () async {
      final fake = FakeStatisticsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final stats = await container.read(statisticsProvider.future);

      expect(stats.totalWords, 0);
      expect(stats.currentStreak, 0);
      expect(stats.dailyWordCount, 0);
      expect(stats.dailyTarget, 500);
    });

    test('reflects seeded today words', () async {
      final fake = FakeStatisticsRepository(dailyTarget: 300);
      final todayKey = DateTime.now();
      final month = todayKey.month.toString().padLeft(2, '0');
      final day = todayKey.day.toString().padLeft(2, '0');
      final key = '${todayKey.year}-$month-$day';
      fake.seedToday(key, words: 250, sessions: 2);

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final stats = await container.read(statisticsProvider.future);

      expect(stats.dailyWordCount, 250);
      expect(stats.todaySessions, 2);
      expect(stats.dailyTarget, 300);
    });

    test('dailyCompletionRatio is 0 when no words written', () async {
      final fake = FakeStatisticsRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final stats = await container.read(statisticsProvider.future);

      expect(stats.dailyCompletionRatio, 0.0);
      expect(stats.dailyTargetReached, isFalse);
    });

    test('dailyTargetReached is true when dailyWordCount >= dailyTarget',
        () async {
      final fake = FakeStatisticsRepository(dailyTarget: 100);
      final todayKey = DateTime.now();
      final month = todayKey.month.toString().padLeft(2, '0');
      final day = todayKey.day.toString().padLeft(2, '0');
      final key = '${todayKey.year}-$month-$day';
      fake.seedToday(key, words: 100, sessions: 1);

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final stats = await container.read(statisticsProvider.future);

      expect(stats.dailyTargetReached, isTrue);
      expect(stats.dailyCompletionRatio, 1.0);
    });

    test('recordSession increments totalWords in watchStats stream', () async {
      final fake = FakeStatisticsRepository();
      await fake.recordSession(
        documentId: 'test-doc',
        wordsDelta: 200,
        durationSeconds: 300,
      );

      final stats = await fake.watchStats().first;
      expect(stats.dailyWordCount, 200);
      expect(stats.todaySessions, 1);
      expect(stats.totalWords, 200);
    });
  });
}
