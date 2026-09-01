import 'package:drift/drift.dart';
import 'package:pluma/core/constants/app_constants.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_dao.g.dart';

@DriftAccessor(tables: [Documents, DocumentVersions])
class TrashDao extends DatabaseAccessor<AppDatabase> with _$TrashDaoMixin {
  TrashDao(super.attachedDatabase);

  Stream<List<DocumentRow>> watchDeleted() {
    return (select(documents)
          ..where((d) => d.isDeleted.equals(true))
          ..orderBy([(d) => OrderingTerm.desc(d.deletedAt)]))
        .watch();
  }

  Future<void> softDelete(String id) {
    return (update(documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restore(String id) {
    return (update(documents)..where((d) => d.id.equals(id))).write(
      const DocumentsCompanion(
        isDeleted: Value(false),
        deletedAt: Value(null),
      ),
    );
  }

  Future<void> deletePermanently(String id) {
    return transaction(() async {
      await (delete(documentVersions)..where((v) => v.documentId.equals(id)))
          .go();
      await (delete(documents)..where((d) => d.id.equals(id))).go();
    });
  }

  Future<void> emptyTrash() {
    return transaction(() async {
      await (delete(documents)..where((d) => d.isDeleted.equals(true))).go();
      await _deleteOrphanedVersions();
    });
  }

  Future<void> purgeExpiredTrash({
    int retentionDays = AppConstants.trashRetentionDays,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    return transaction(() async {
      await (delete(documents)
            ..where(
              (d) =>
                  d.isDeleted.equals(true) &
                  d.deletedAt.isSmallerThanValue(cutoff),
            ))
          .go();
      await _deleteOrphanedVersions();
    });
  }

  // Removes versions whose document no longer exists. Used after bulk deletes
  // (emptyTrash / purge) where the affected document ids aren't enumerated.
  Future<void> _deleteOrphanedVersions() {
    return customStatement(
      'DELETE FROM document_versions WHERE document_id NOT IN '
      '(SELECT id FROM documents)',
    );
  }
}

@riverpod
TrashDao trashDao(Ref ref) => ref.watch(appDatabaseProvider).trashDao;
