import 'dart:async';

import 'package:pluma/features/statistics/data/statistics_repository_impl.dart';
import 'package:pluma/features/statistics/domain/daily_stats.dart';
import 'package:pluma/features/statistics/domain/statistics_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistics_notifier.g.dart';

@riverpod
class StatisticsNotifier extends _$StatisticsNotifier {
  late StatisticsRepository _repo;
  StreamSubscription<WritingStats>? _sub;

  @override
  Future<WritingStats> build() async {
    _repo = ref.watch(statisticsRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());

    final initial = await _repo.watchStats().first;
    _sub = _repo.watchStats().skip(1).listen((stats) {
      state = AsyncData(stats);
    });
    return initial;
  }
}
