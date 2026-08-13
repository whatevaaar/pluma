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
    required String documentId,
    required int wordsDelta,
    required int durationSeconds,
    DateTime? startedAt,
  }) async {
    final words = wordsDelta < 0 ? 0 : wordsDelta;
    _wordsToday += words;
    _sessionsToday++;
    _totalWords += words;
  }

  @override
  Future<Map<String, int>> getHeatmapData({int days = 365}) async => {};

  WritingStats _buildStats() => WritingStats(
        totalWords: _totalWords,
        currentStreak: streak.computeCurrentStreak(
          _activeDates,
          DateTime.now().toIso8601String().substring(0, 10),
        ),
        longestStreak: streak.computeLongestStreak(_activeDates),
        dailyWordCount: _wordsToday,
        dailyTarget: dailyTarget,
        todaySessions: _sessionsToday,
        totalDaysActive: _totalDaysActive,
        bestDay: _wordsToday,
        bestSession: 0,
        averageDaily: _totalDaysActive > 0 ? _totalWords ~/ _totalDaysActive : 0,
        heatmapData: const {},
      );
}
