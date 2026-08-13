import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/extensions/datetime_ext.dart';
import '../domain/document.dart';
import '../domain/document_repository.dart';
import '../domain/project.dart';
import 'documents_dao.dart';
import 'projects_dao.dart';

part 'document_repository_impl.g.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._docsDao, this._projectsDao);

  final DocumentsDao _docsDao;
  final ProjectsDao _projectsDao;

  // --- Documents ---

  @override
  Stream<List<Document>> watchAll({
    String? projectId,
    SortOrder order = SortOrder.updatedDesc,
  }) {
    return _docsDao.watchActive(projectId: projectId).map(
          (rows) => rows.map(_mapDocument).toList()..sort(_comparatorFor(order)),
        );
  }

  @override
  Stream<List<Document>> watchRecent({int limit = 10}) {
    return _docsDao.watchRecent(limit).map(
          (rows) => rows.map(_mapDocument).toList(),
        );
  }

  @override
  Stream<List<Document>> watchFavorites() {
    return _docsDao.watchFavorites().map(
          (rows) => rows.map(_mapDocument).toList(),
        );
  }

  @override
  Future<Document?> findById(String id) async {
    final row = await _docsDao.findById(id);
    return row == null ? null : _mapDocument(row);
  }

  @override
  Future<List<Document>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = await _docsDao.searchFullText(query.trim());
    return rows.map(_mapDocument).toList();
  }

  @override
  Future<String> create({String? projectId, String? title}) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await _docsDao.insert(
      DocumentsCompanion.insert(
        id: id,
        projectId: Value(projectId),
        title: title ?? '',
        content: '{"ops":[{"insert":"\\n"}]}', // empty Quill document
        plainText: '',
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<void> save(Document document) {
    return _docsDao.upsert(
      DocumentsCompanion(
        id: Value(document.id),
        projectId: Value(document.projectId),
        title: Value(document.title),
        content: Value(document.content),
        plainText: Value(document.plainText),
        wordCount: Value(document.wordCount),
        charCount: Value(document.charCount),
        isFavorite: Value(document.isFavorite),
        isDeleted: Value(document.isDeleted),
        deletedAt: Value(document.deletedAt),
        targetWordCount: Value(document.targetWordCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = await _docsDao.findById(id);
    if (doc == null) return;
    await _docsDao.updateFavorite(id, isFavorite: !doc.isFavorite);
  }

  @override
  Future<void> moveToProject(String documentId, String? projectId) {
    return _docsDao.updateProject(documentId, projectId);
  }

  // --- Projects ---

  @override
  Stream<List<Project>> watchProjects({bool includeArchived = false}) {
    return _projectsDao.watchAll(includeArchived: includeArchived).map(
          (rows) => rows.map(_mapProject).toList(),
        );
  }

  @override
  Future<Project?> findProjectById(String id) async {
    final row = await _projectsDao.findById(id);
    return row == null ? null : _mapProject(row);
  }

  @override
  Future<String> createProject(String name, {String? color}) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await _projectsDao.upsert(
      ProjectsCompanion.insert(
        id: id,
        name: name,
        color: Value(color),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<void> saveProject(Project project) {
    return _projectsDao.upsert(
      ProjectsCompanion(
        id: Value(project.id),
        name: Value(project.name),
        description: Value(project.description),
        color: Value(project.color),
        isArchived: Value(project.isArchived),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> archiveProject(String id) => _projectsDao.archive(id);

  // --- Mappers ---

  Document _mapDocument(DocumentRow row) => Document(
        id: row.id,
        projectId: row.projectId,
        title: row.title,
        content: row.content,
        plainText: row.plainText,
        wordCount: row.wordCount,
        charCount: row.charCount,
        isFavorite: row.isFavorite,
        isDeleted: row.isDeleted,
        deletedAt: row.deletedAt,
        targetWordCount: row.targetWordCount,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  Project _mapProject(ProjectRow row) => Project(
        id: row.id,
        name: row.name,
        description: row.description,
        color: row.color,
        isArchived: row.isArchived,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  Comparator<Document> _comparatorFor(SortOrder order) => switch (order) {
        SortOrder.updatedDesc => (a, b) => b.updatedAt.compareTo(a.updatedAt),
        SortOrder.updatedAsc => (a, b) => a.updatedAt.compareTo(b.updatedAt),
        SortOrder.createdDesc => (a, b) => b.createdAt.compareTo(a.createdAt),
        SortOrder.titleAsc => (a, b) =>
            a.displayTitle.compareTo(b.displayTitle),
        SortOrder.wordCountDesc => (a, b) =>
            b.wordCount.compareTo(a.wordCount),
      };
}

@riverpod
DocumentRepository documentRepository(Ref ref) => DocumentRepositoryImpl(
      ref.watch(documentsDaoProvider),
      ref.watch(projectsDaoProvider),
    );
