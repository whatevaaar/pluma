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

    // Single subscription: captures the initial value AND all future updates.
    // The previous two-stream pattern (.first + .skip(1)) had a race condition
    // where DB changes between the two subscriptions were silently lost.
    // Using one Completer-based subscription eliminates this gap.
    final completer = Completer<WritingStats>();
    _sub = _repo.watchStats().listen(
      (stats) {
        if (!completer.isCompleted) {
          completer.complete(stats);
        } else {
          state = AsyncData(stats);
        }
      },
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        } else {
          state = AsyncError(e, st);
        }
      },
    );
    return completer.future;
  }
}
