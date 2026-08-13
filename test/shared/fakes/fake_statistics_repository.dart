import 'package:pluma/features/statistics/domain/daily_stats.dart';
import 'package:pluma/features/statistics/domain/statistics_repository.dart';
import 'package:pluma/features/statistics/domain/streak_calculator.dart' as streak;

class FakeStatisticsRepository implements StatisticsRepository {
  int dailyTarget;
  int _wordsToday = 0;
  int _sessionsToday = 0;
  int _totalWords = 0;
  int _totalDaysActive = 0;
  final _activeDates = <String>[];

  FakeStatisticsRepository({this.dailyTarget = 500});

  /// Seed an active day for streak/heatmap testing.
  void seedDay(String dateKey, int words) {
    _totalWords += words;
    if (words > 0 && !_activeDates.contains(dateKey)) {
      _activeDates.add(dateKey);
      _totalDaysActive++;
    }
  }

  void seedToday(String todayKey, {int words = 0, int sessions = 0}) {
    _wordsToday = words;
    _sessionsToday = sessions;
    if (words > 0 && !_activeDates.contains(todayKey)) {
      _activeDates.add(todayKey);
      _totalDaysActive++;
      _totalWords += words;
    }
  }

  @override
  Stream<WritingStats> watchStats() => Stream.value(_buildStats());

  @override
  Future<void> recordSession({
    required int wordsDelta,
    required int durationSeconds,
  }) async {
    _wordsToday += wordsDelta;
    _sessionsToday++;
    _totalWords += wordsDelta;
  }

  @override
  Future<Map<String, int>> getHeatmapData({int days = 365}) async => {};

  @override
  Future<int> computeCurrentStreak() async {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return streak.computeCurrentStreak(_activeDates, key);
  }

  @override
  Future<int> computeLongestStreak() async =>
      streak.computeLongestStreak(_activeDates);

  @override
  Future<int> computeBestDay() async => _wordsToday;

  @override
  Future<int> computeBestSession() async => 0;

  WritingStats _buildStats() => WritingStats(
        totalWords: _totalWords,
        currentStreak: 0,
        longestStreak: 0,
        dailyWordCount: _wordsToday,
        dailyTarget: dailyTarget,
        todaySessions: _sessionsToday,
        totalDaysActive: _totalDaysActive,
        bestDay: _wordsToday,
        bestSession: 0,
        averageDaily: _totalDaysActive > 0 ? _totalWords ~/ _totalDaysActive : 0,
        heatmapData: {},
      );
}
