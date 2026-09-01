import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_dao.g.dart';

/// Bulk read/replace access across every content table, for full-library
/// backup and restore.
@DriftAccessor(tables: [Projects, Documents, DailyStats, DocumentVersions])
class BackupDao extends DatabaseAccessor<AppDatabase> with _$BackupDaoMixin {
  BackupDao(super.attachedDatabase);

  Future<List<ProjectRow>> getAllProjects() => select(projects).get();

  // All documents, including soft-deleted ones, so the trash survives a
  // backup/restore round-trip.
  Future<List<DocumentRow>> getAllDocuments() => select(documents).get();

  Future<List<DailyStat>> getAllDailyStats() => select(dailyStats).get();

  /// Wipes all content and replaces it with the given rows, in a single
  /// transaction. Uses DELETE (not DROP) so the FTS triggers keep the search
  /// index consistent. Version history is cleared — snapshots belong to the
  /// documents being replaced.
  Future<void> replaceAll({
    required List<ProjectRow> projectRows,
    required List<DocumentRow> documentRows,
    required List<DailyStat> dailyStatRows,
  }) {
    return transaction(() async {
      // FK-safe delete order: dependents before parents.
      await delete(documentVersions).go();
      await delete(documents).go();
      await delete(dailyStats).go();
      await delete(projects).go();

      // FK-safe insert order: projects before the documents referencing them.
      await batch((b) {
        b
          ..insertAll(projects, projectRows)
          ..insertAll(documents, documentRows)
          ..insertAll(dailyStats, dailyStatRows);
      });
    });
  }
}

@riverpod
BackupDao backupDao(Ref ref) => ref.watch(appDatabaseProvider).backupDao;
