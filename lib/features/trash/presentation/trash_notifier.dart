import 'dart:async';

import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/trash/data/trash_repository_impl.dart';
import 'package:pluma/features/trash/domain/trash_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_notifier.g.dart';

@riverpod
class TrashNotifier extends _$TrashNotifier {
  late TrashRepository _repo;
  StreamSubscription<List<Document>>? _sub;

  @override
  Future<List<Document>> build() async {
    _repo = ref.watch(trashRepositoryProvider);
    ref.onDispose(() => _sub?.cancel());

    final initial = await _repo.watchDeleted().first;
    _sub = _repo.watchDeleted().listen((docs) {
      state = AsyncData(docs);
    });
    return initial;
  }

  Future<void> restore(String id) => _repo.restore(id);

  Future<void> deletePermanently(String id) => _repo.deletePermanently(id);

  Future<void> emptyTrash() => _repo.emptyTrash();
}
