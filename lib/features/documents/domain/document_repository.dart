import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/documents/domain/project.dart';

/// Contract between the presentation layer and the data layer for documents.
/// All methods operate only on non-deleted documents unless stated otherwise.
abstract interface class DocumentRepository {
  // --- Documents ---

  Stream<List<Document>> watchAll({String? projectId});

  Stream<List<Document>> watchRecent({int limit = 10});

  Stream<List<Document>> watchFavorites();

  Future<Document?> findById(String id);

  Future<List<Document>> search(String query);

  Future<String> create({String? projectId, String? title});

  Future<void> save(Document document);

  Future<void> rename(String id, String title);

  Future<void> softDelete(String id);

  Future<void> toggleFavorite(String id);

  Future<void> moveToProject(String documentId, String? projectId);

  // --- Projects ---

  Stream<List<Project>> watchProjects({bool includeArchived = false});

  Future<Project?> findProjectById(String id);

  Future<String> createProject(String name, {String? color});

  Future<void> saveProject(Project project);

  Future<void> archiveProject(String id);
}

enum SortOrder {
  updatedDesc,
  updatedAsc,
  createdDesc,
  titleAsc,
  wordCountDesc,
}
