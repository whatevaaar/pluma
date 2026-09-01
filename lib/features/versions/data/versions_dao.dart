import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'versions_dao.g.dart';

@DriftAccessor(tables: [DocumentVersions])
class VersionsDao extends DatabaseAccessor<AppDatabase>
    with _$VersionsDaoMixin {
  VersionsDao(super.attachedDatabase);

  Stream<List<DocumentVersionRow>> watchForDocument(String documentId) {
    return (select(documentVersions)
          ..where((v) => v.documentId.equals(documentId))
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt)]))
        .watch();
  }

  Future<DocumentVersionRow?> findById(String id) {
    return (select(documentVersions)..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> countForDocument(String documentId) async {
    final count = documentVersions.id.count();
    final query = selectOnly(documentVersions)
      ..addColumns([count])
      ..where(documentVersions.documentId.equals(documentId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> insert(DocumentVersionsCompanion companion) {
    return into(documentVersions).insert(companion);
  }

  Future<void> deleteById(String id) {
    return (delete(documentVersions)..where((v) => v.id.equals(id))).go();
  }

  Future<void> deleteAllForDocument(String documentId) {
    return (delete(documentVersions)
          ..where((v) => v.documentId.equals(documentId)))
        .go();
  }

  /// Keeps only the newest [keep] versions for [documentId], deleting older
  /// ones. Uses a subquery so the cutoff is computed by the database.
  Future<void> pruneOldest(String documentId, {required int keep}) {
    return customStatement(
      'DELETE FROM document_versions '
      'WHERE document_id = ? AND id NOT IN ( '
      'SELECT id FROM document_versions '
      'WHERE document_id = ? ORDER BY created_at DESC LIMIT ? )',
      [documentId, documentId, keep],
    );
  }
}

@riverpod
VersionsDao versionsDao(Ref ref) => ref.watch(appDatabaseProvider).versionsDao;
