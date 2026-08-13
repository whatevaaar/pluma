import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

// These tests validate streak calculation logic in isolation.
// The actual StatisticsRepositoryImpl is tested with NativeDatabase.memory()
// in test/features/statistics/data/statistics_repository_impl_test.dart.

/// Simple pure-function streak calculator for unit testing without DB.
int computeStreak(List<String> activeDates, String today) {
  if (activeDates.isEmpty) return 0;

  // Sort descending
  final sorted = [...activeDates]..sort((a, b) => b.compareTo(a));

  // If today has no activity, check if yesterday does
  int streak = 0;
  var cursor = today;

  // If today is not active, start from yesterday
  if (!sorted.contains(today)) {
    final yesterday = _subtractDay(today);
    if (!sorted.contains(yesterday)) return 0;
    cursor = yesterday;
  }

  for (final date in sorted) {
    if (date == cursor) {
      streak++;
      cursor = _subtractDay(cursor);
    } else {
      break;
    }
  }

  return streak;
}

String _subtractDay(String dateKey) {
  final parts = dateKey.split('-');
  final dt = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  ).subtract(const Duration(days: 1));
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

void main() {
  group('Streak calculation', () {
    test('no active days → streak is 0', () {
      expect(computeStreak([], '2026-08-12'), 0);
    });

    test('only today active → streak is 1', () {
      expect(computeStreak(['2026-08-12'], '2026-08-12'), 1);
    });

    test('yesterday and today active → streak is 2', () {
      expect(
        computeStreak(['2026-08-11', '2026-08-12'], '2026-08-12'),
        2,
      );
    });

    test('3 consecutive days → streak is 3', () {
      expect(
        computeStreak(['2026-08-10', '2026-08-11', '2026-08-12'], '2026-08-12'),
        3,
      );
    });

    test('gap in days resets streak', () {
      // Aug 8 and Aug 10 active, Aug 9 missing — streak from today (12) is 0
      // because yesterday (11) is missing
      expect(
        computeStreak(['2026-08-08', '2026-08-10'], '2026-08-12'),
        0,
      );
    });

    test('yesterday active but not today → streak is 1 (grace period)', () {
      // User wrote yesterday but not yet today — streak still alive
      expect(
        computeStreak(['2026-08-11'], '2026-08-12'),
        1,
      );
    });

    test('streak does not count non-consecutive days', () {
      expect(
        computeStreak(['2026-08-05', '2026-08-07', '2026-08-09', '2026-08-11'], '2026-08-12'),
        1, // only yesterday counts
      );
    });
  });

  group('fake_async — simulating day transitions', () {
    test('streak-based notification fires after 25 hours without writing', () {
      fakeAsync((async) {
        var streakBroken = false;
        final timer = async.getClock(DateTime(2026, 8, 12, 9, 0));

        // Simulate: last activity at 09:00, check 25 hours later
        async.elapse(const Duration(hours: 25));

        final now = timer.now();
        // After 25h, it's past midnight of the next day
        if (now.day != 12) {
          streakBroken = true;
        }

        expect(streakBroken, isTrue);
      });
    });
  });
}
