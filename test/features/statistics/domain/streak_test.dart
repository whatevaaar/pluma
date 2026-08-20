import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/statistics/domain/streak_calculator.dart';

// Tests for the actual domain functions in streak_calculator.dart.
// Previous version tested a local reimplementation — this file tests the
// real functions so regressions in the domain are caught directly.

void main() {
  group('computeCurrentStreak', () {
    test('empty active dates → 0', () {
      expect(computeCurrentStreak([], '2026-08-12'), 0);
    });

    test('only today active → 1', () {
      expect(computeCurrentStreak(['2026-08-12'], '2026-08-12'), 1);
    });

    test('today + yesterday → 2', () {
      expect(
        computeCurrentStreak(['2026-08-11', '2026-08-12'], '2026-08-12'),
        2,
      );
    });

    test('3 consecutive days → 3', () {
      expect(
        computeCurrentStreak(
          ['2026-08-10', '2026-08-11', '2026-08-12'],
          '2026-08-12',
        ),
        3,
      );
    });

    test('grace period: yesterday active, not today → streak alive (1)', () {
      // User has not written today yet — streak should not break until
      // tomorrow. This is the "grace period" behaviour.
      expect(computeCurrentStreak(['2026-08-11'], '2026-08-12'), 1);
    });

    test('grace period: 2-day streak ending yesterday → 2', () {
      expect(
        computeCurrentStreak(
          ['2026-08-10', '2026-08-11'],
          '2026-08-12',
        ),
        2,
      );
    });

    test('neither today nor yesterday active → 0', () {
      expect(computeCurrentStreak(['2026-08-10'], '2026-08-12'), 0);
    });

    test('gap two days ago breaks streak even if yesterday active', () {
      // Active: Aug 9, Aug 11. Aug 10 is missing → streak from yesterday is 1,
      // but the day before yesterday broke it.
      expect(
        computeCurrentStreak(['2026-08-09', '2026-08-11'], '2026-08-12'),
        1,
      );
    });

    test('non-consecutive days before streak do not count', () {
      // Alternating days: only yesterday contributes.
      expect(
        computeCurrentStreak(
          ['2026-08-05', '2026-08-07', '2026-08-09', '2026-08-11'],
          '2026-08-12',
        ),
        1,
      );
    });

    test('unsorted input is handled correctly', () {
      // Dates passed in random order should still work.
      expect(
        computeCurrentStreak(
          ['2026-08-12', '2026-08-10', '2026-08-11'],
          '2026-08-12',
        ),
        3,
      );
    });

    test('month boundary: Feb 28 → Mar 1 is consecutive', () {
      expect(
        computeCurrentStreak(['2026-02-28', '2026-03-01'], '2026-03-01'),
        2,
      );
    });

    test('year boundary: Dec 31 → Jan 1 is consecutive', () {
      expect(
        computeCurrentStreak(['2025-12-31', '2026-01-01'], '2026-01-01'),
        2,
      );
    });
  });

  group('computeLongestStreak', () {
    test('empty list → 0', () {
      expect(computeLongestStreak([]), 0);
    });

    test('single day → 1', () {
      expect(computeLongestStreak(['2026-08-12']), 1);
    });

    test('two consecutive days → 2', () {
      expect(computeLongestStreak(['2026-08-11', '2026-08-12']), 2);
    });

    test('two non-consecutive days → 1', () {
      expect(computeLongestStreak(['2026-08-10', '2026-08-12']), 1);
    });

    test('picks the longer of two disjoint streaks', () {
      // Streak of 2 (Aug 10–11) and streak of 3 (Aug 14–16) → 3.
      expect(
        computeLongestStreak([
          '2026-08-10',
          '2026-08-11',
          '2026-08-14',
          '2026-08-15',
          '2026-08-16',
        ]),
        3,
      );
    });

    test('longest streak in the middle is found', () {
      // Streak: 1(Jan), 3(Mar–May), 2(Jul–Aug) → longest 3.
      expect(
        computeLongestStreak([
          '2026-01-10',
          '2026-03-01',
          '2026-03-02',
          '2026-03-03',
          '2026-07-20',
          '2026-07-21',
        ]),
        3,
      );
    });

    test('all days consecutive → streak equals list length', () {
      expect(
        computeLongestStreak([
          '2026-08-10',
          '2026-08-11',
          '2026-08-12',
          '2026-08-13',
          '2026-08-14',
        ]),
        5,
      );
    });

    test('unsorted input is handled correctly', () {
      expect(
        computeLongestStreak([
          '2026-08-12',
          '2026-08-10',
          '2026-08-11',
        ]),
        3,
      );
    });

    test('month boundary counts as consecutive', () {
      expect(
        computeLongestStreak(['2026-01-31', '2026-02-01', '2026-02-02']),
        3,
      );
    });
  });
}
