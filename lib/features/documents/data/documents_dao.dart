import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'documents_dao.g.dart';

@DriftAccessor(tables: [Documents, Projects])
class DocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.attachedDatabase);

  Stream<List<DocumentRow>> watchActive({String? projectId}) {
    final query = select(documents)
      ..where((d) => d.isDeleted.equals(false));
    if (projectId != null) {
      query.where((d) => d.projectId.equals(projectId));
    }
    query.orderBy([(d) => OrderingTerm.desc(d.updatedAt)]);
    return query.watch();
  }

  Stream<List<DocumentRow>> watchRecent(int limit) {
    return (select(documents)
          ..where((d) => d.isDeleted.equals(false))
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)])
          ..limit(limit))
        .watch();
  }

  Stream<List<DocumentRow>> watchFavorites() {
    return (select(documents)
          ..where((d) => d.isDeleted.equals(false) & d.isFavorite.equals(true))
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
        .watch();
  }

  Future<DocumentRow?> findById(String id) {
    return (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  Future<List<DocumentRow>> searchFullText(String query) async {
    final sanitized = _sanitizeFts(query);
    if (sanitized.isEmpty) return [];
    // FTS5 query via raw SQL — Drift doesn't model virtual tables natively
    final results = await customSelect(
      '''
      SELECT d.* FROM documents d
      INNER JOIN documents_fts fts ON d.rowid = fts.rowid
      WHERE documents_fts MATCH ? AND d.is_deleted = 0
      ORDER BY rank
      LIMIT 50
      ''',
      variables: [Variable.withString(sanitized)],
      readsFrom: {documents},
    ).get();

    return results
        .map((row) => DocumentRow.fromJson(row.data))
        .toList();
  }

  // Wraps each whitespace-separated token in FTS5 phrase quotes so special
  // characters (", *, OR, AND, NOT, parentheses) cannot break the query.
  String _sanitizeFts(String query) {
    final tokens =
        query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    return tokens.map((t) => '"${t.replaceAll('"', '""')}"').join(' ');
  }

  Future<String> insert(DocumentsCompanion companion) async {
    await into(documents).insert(companion);
    return companion.id.value;
  }

  Future<void> upsert(DocumentsCompanion companion) {
    return into(documents).insertOnConflictUpdate(companion);
  }

  Future<void> updateFavorite(String id, {required bool isFavorite}) {
    return (update(documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future<void> updateProject(String documentId, String? projectId) {
    return (update(documents)..where((d) => d.id.equals(documentId))).write(
      DocumentsCompanion(projectId: Value(projectId)),
    );
  }
}

@riverpod
DocumentsDao documentsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).documentsDao;
