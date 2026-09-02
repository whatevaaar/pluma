import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/documents/data/document_row_ext.dart';
import 'package:pluma/features/documents/data/documents_dao.dart';
import 'package:pluma/features/documents/data/projects_dao.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/documents/domain/document_repository.dart';
import 'package:pluma/features/documents/domain/project.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'document_repository_impl.g.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._docsDao, this._projectsDao);

  final DocumentsDao _docsDao;
  final ProjectsDao _projectsDao;

  // --- Documents ---

  @override
  Stream<List<Document>> watchAll({String? projectId}) {
    return _docsDao
        .watchActive(projectId: projectId)
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Stream<List<Document>> watchRecent({int limit = 10}) {
    return _docsDao
        .watchRecent(limit)
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Stream<List<Document>> watchFavorites() {
    return _docsDao
        .watchFavorites()
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<Document?> findById(String id) async {
    final row = await _docsDao.findById(id);
    return row?.toDomain();
  }

  @override
  Future<List<Document>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final rows = await _docsDao.searchFullText(query.trim());
    return rows.map((r) => r.toDomain()).toList();
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
        content: r'{"ops":[{"insert":"\n"}]}',
        plainText: '',
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  @override
  Future<String> createWithContent({
    required String title,
    required String content,
    required String plainText,
    required int wordCount,
    required int charCount,
    String? projectId,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await _docsDao.insert(
      DocumentsCompanion.insert(
        id: id,
        projectId: Value(projectId),
        title: title,
        content: content,
        plainText: plainText,
        wordCount: Value(wordCount),
        charCount: Value(charCount),
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
  Future<void> rename(String id, String title) {
    return _docsDao.rename(id, title, DateTime.now());
  }

  @override
  Future<void> softDelete(String id) {
    return _docsDao.softDelete(id, DateTime.now());
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
    return _projectsDao
        .watchAll(includeArchived: includeArchived)
        .map((rows) => rows.map(_mapProject).toList());
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

  Project _mapProject(ProjectRow row) => Project(
        id: row.id,
        name: row.name,
        description: row.description,
        color: row.color,
        isArchived: row.isArchived,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}

@riverpod
DocumentRepository documentRepository(Ref ref) => DocumentRepositoryImpl(
      ref.watch(documentsDaoProvider),
      ref.watch(projectsDaoProvider),
    );
