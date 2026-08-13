import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';

part 'documents_dao.g.dart';

@DriftAccessor(tables: [Documents, Projects])
class DocumentsDao extends DatabaseAccessor<AppDatabase> with _$DocumentsDaoMixin {
  DocumentsDao(super.db);

  Stream<List<Document>> watchActive({String? projectId}) {
    final query = select(documents)
      ..where((d) => d.isDeleted.equals(false));
    if (projectId != null) {
      query.where((d) => d.projectId.equals(projectId));
    }
    query.orderBy([(d) => OrderingTerm.desc(d.updatedAt)]);
    return query.watch();
  }

  Stream<List<Document>> watchRecent(int limit) {
    return (select(documents)
          ..where((d) => d.isDeleted.equals(false))
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)])
          ..limit(limit))
        .watch();
  }

  Stream<List<Document>> watchFavorites() {
    return (select(documents)
          ..where((d) => d.isDeleted.equals(false) & d.isFavorite.equals(true))
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
        .watch();
  }

  Future<Document?> findById(String id) {
    return (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  Future<List<Document>> searchFullText(String query) async {
    // FTS5 query via raw SQL — Drift doesn't model virtual tables natively
    final results = await customSelect(
      '''
      SELECT d.* FROM documents d
      INNER JOIN documents_fts fts ON d.rowid = fts.rowid
      WHERE documents_fts MATCH ? AND d.is_deleted = 0
      ORDER BY rank
      LIMIT 50
      ''',
      variables: [Variable.withString(query)],
      readsFrom: {documents},
    ).get();

    return results
        .map((row) => Document.fromJson(row.data))
        .toList();
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
DocumentsDao documentsDao(Ref ref) => ref.watch(appDatabaseProvider).documentsDao;
