import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/document_repository_impl.dart';
import '../domain/document.dart';
import '../domain/document_repository.dart';
import '../domain/project.dart';

part 'library_notifier.freezed.dart';
part 'library_notifier.g.dart';

@freezed
class LibraryState with _$LibraryState {
  const factory LibraryState({
    required List<Document> documents,
    required List<Project> projects,
    required List<Document> recentDocuments,
    required SortOrder sortOrder,
    required String searchQuery,
    required List<Document> searchResults,
    required bool isSearching,
  }) = _LibraryState;

  factory LibraryState.initial() => const LibraryState(
        documents: [],
        projects: [],
        recentDocuments: [],
        sortOrder: SortOrder.updatedDesc,
        searchQuery: '',
        searchResults: [],
        isSearching: false,
      );
}

@riverpod
class LibraryNotifier extends _$LibraryNotifier {
  late DocumentRepository _repo;

  @override
  Stream<LibraryState> build() async* {
    _repo = ref.watch(documentRepositoryProvider);

    // Combine docs + projects + recent into a single state stream
    yield LibraryState.initial();

    await for (final docs in _repo.watchAll()) {
      final state = this.state.valueOrNull ?? LibraryState.initial();
      yield state.copyWith(documents: docs);
    }
  }

  Future<String> createDocument({String? projectId}) async {
    return _repo.create(projectId: projectId);
  }

  Future<void> toggleFavorite(String documentId) {
    return _repo.toggleFavorite(documentId);
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = AsyncData(
        (state.valueOrNull ?? LibraryState.initial()).copyWith(
          searchQuery: '',
          searchResults: [],
          isSearching: false,
        ),
      );
      return;
    }

    state = AsyncData(
      (state.valueOrNull ?? LibraryState.initial()).copyWith(
        searchQuery: query,
        isSearching: true,
      ),
    );

    final results = await _repo.search(query);
    state = AsyncData(
      (state.valueOrNull ?? LibraryState.initial()).copyWith(
        searchResults: results,
        isSearching: false,
      ),
    );
  }

  void setSortOrder(SortOrder order) {
    final current = state.valueOrNull ?? LibraryState.initial();
    state = AsyncData(current.copyWith(sortOrder: order));
  }
}
