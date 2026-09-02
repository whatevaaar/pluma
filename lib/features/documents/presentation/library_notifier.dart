import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pluma/features/documents/data/document_repository_impl.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/documents/domain/document_repository.dart';
import 'package:pluma/features/documents/domain/project.dart';
import 'package:pluma/features/import/data/document_importer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_notifier.freezed.dart';
part 'library_notifier.g.dart';

@freezed
abstract class LibraryState with _$LibraryState {
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
  StreamSubscription<List<Document>>? _docsSub;
  StreamSubscription<List<Project>>? _projectsSub;

  @override
  Future<LibraryState> build() async {
    _repo = ref.watch(documentRepositoryProvider);

    ref.onDispose(() {
      unawaited(_docsSub?.cancel());
      unawaited(_projectsSub?.cancel());
    });

    final docs = await _repo.watchAll().first;
    final projects = await _repo.watchProjects().first;
    final recent = await _repo.watchRecent().first;

    _docsSub = _repo.watchAll().listen((docs) {
      final current = state.value;
      if (current == null) return;
      state = AsyncData(
        current.copyWith(documents: _sort(docs, current.sortOrder)),
      );
    });

    _projectsSub = _repo.watchProjects().listen((projects) {
      final current = state.value;
      if (current == null) return;
      state = AsyncData(current.copyWith(projects: projects));
    });

    return LibraryState(
      documents: _sort(docs, SortOrder.updatedDesc),
      projects: projects,
      recentDocuments: recent,
      sortOrder: SortOrder.updatedDesc,
      searchQuery: '',
      searchResults: [],
      isSearching: false,
    );
  }

  // --- Document actions ---

  Future<String> createDocument({String? projectId}) {
    return _repo.create(projectId: projectId);
  }

  /// Persists a document parsed from an imported file. Returns the new id.
  Future<String> importDocument(ImportedDocument imported) {
    return _repo.createWithContent(
      title: imported.title,
      content: imported.content,
      plainText: imported.plainText,
      wordCount: imported.wordCount,
      charCount: imported.charCount,
    );
  }

  Future<void> deleteDocument(String id) {
    return _repo.softDelete(id);
  }

  Future<void> renameDocument(String id, String title) {
    return _repo.rename(id, title);
  }

  Future<void> toggleFavorite(String documentId) {
    return _repo.toggleFavorite(documentId);
  }

  Future<void> moveDocument(String documentId, String? projectId) {
    return _repo.moveToProject(documentId, projectId);
  }

  // --- Project actions ---

  Future<String> createProject(String name, {String? color}) {
    return _repo.createProject(name, color: color);
  }

  // --- Sort ---

  void setSortOrder(SortOrder order) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        sortOrder: order,
        documents: _sort(current.documents, order),
      ),
    );
  }

  // --- Search ---

  Future<void> search(String query) async {
    final current = state.value ?? LibraryState.initial();

    if (query.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(
          searchQuery: '',
          searchResults: [],
          isSearching: false,
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(searchQuery: query, isSearching: true),
    );

    final results = await _repo.search(query);
    state = AsyncData(
      (state.value ?? current).copyWith(
        searchResults: results,
        isSearching: false,
      ),
    );
  }

  // --- Private ---

  List<Document> _sort(List<Document> docs, SortOrder order) {
    final sorted = List<Document>.from(docs);
    switch (order) {
      case SortOrder.updatedDesc:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortOrder.updatedAsc:
        sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case SortOrder.createdDesc:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOrder.titleAsc:
        sorted.sort(
          (a, b) => a.displayTitle.compareTo(b.displayTitle),
        );
      case SortOrder.wordCountDesc:
        sorted.sort((a, b) => b.wordCount.compareTo(a.wordCount));
    }
    return sorted;
  }
}
