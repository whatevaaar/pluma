import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/documents/domain/document_repository.dart';
import 'package:pluma/features/documents/domain/project.dart';
import 'package:uuid/uuid.dart';

/// Stateful in-memory fake for testing without a real database.
/// Encodes the expected behavior once; individual tests don't re-stub.
class FakeDocumentRepository implements DocumentRepository {
  final _docs = <String, Document>{};
  final _projects = <String, Project>{};

  @override
  Stream<List<Document>> watchAll({
    String? projectId,
    SortOrder order = SortOrder.updatedDesc,
  }) {
    return Stream.value(
      _docs.values
          .where((d) => !d.isDeleted)
          .where((d) => projectId == null || d.projectId == projectId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Stream<List<Document>> watchRecent({int limit = 10}) {
    final all = _docs.values
        .where((d) => !d.isDeleted)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Stream.value(all.take(limit).toList());
  }

  @override
  Stream<List<Document>> watchFavorites() {
    return Stream.value(
      _docs.values.where((d) => !d.isDeleted && d.isFavorite).toList(),
    );
  }

  @override
  Future<Document?> findById(String id) async => _docs[id];

  @override
  Future<List<Document>> search(String query) async {
    final q = query.toLowerCase();
    return _docs.values
        .where((d) => !d.isDeleted)
        .where(
          (d) =>
              d.title.toLowerCase().contains(q) ||
              d.plainText.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<String> create({String? projectId, String? title}) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    _docs[id] = Document(
      id: id,
      projectId: projectId,
      title: title ?? '',
      content: r'{"ops":[{"insert":"\n"}]}',
      plainText: '',
      wordCount: 0,
      charCount: 0,
      isFavorite: false,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    return id;
  }

  @override
  Future<void> save(Document document) async {
    _docs[document.id] = document;
  }

  @override
  Future<void> rename(String id, String title) async {
    final doc = _docs[id];
    if (doc != null) {
      _docs[id] = doc.copyWith(title: title, updatedAt: DateTime.now());
    }
  }

  @override
  Future<void> softDelete(String id) async {
    final doc = _docs[id];
    if (doc != null) {
      _docs[id] = doc.copyWith(isDeleted: true, deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = _docs[id];
    if (doc != null) _docs[id] = doc.copyWith(isFavorite: !doc.isFavorite);
  }

  @override
  Future<void> moveToProject(String documentId, String? projectId) async {
    final doc = _docs[documentId];
    if (doc != null) _docs[documentId] = doc.copyWith(projectId: projectId);
  }

  @override
  Stream<List<Project>> watchProjects({bool includeArchived = false}) {
    return Stream.value(
      _projects.values
          .where((p) => includeArchived || !p.isArchived)
          .toList(),
    );
  }

  @override
  Future<Project?> findProjectById(String id) async => _projects[id];

  @override
  Future<String> createProject(String name, {String? color}) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    _projects[id] = Project(
      id: id,
      name: name,
      color: color,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    return id;
  }

  @override
  Future<void> saveProject(Project project) async {
    _projects[project.id] = project;
  }

  @override
  Future<void> archiveProject(String id) async {
    final p = _projects[id];
    if (p != null) _projects[id] = p.copyWith(isArchived: true);
  }
}
