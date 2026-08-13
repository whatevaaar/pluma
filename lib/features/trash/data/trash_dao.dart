import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';

part 'trash_dao.g.dart';

@DriftAccessor(tables: [Documents])
class TrashDao extends DatabaseAccessor<AppDatabase> with _$TrashDaoMixin {
  TrashDao(super.db);

  Stream<List<Document>> watchDeleted() {
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
    return (delete(documents)..where((d) => d.id.equals(id))).go();
  }
}

@riverpod
TrashDao trashDao(Ref ref) => ref.watch(appDatabaseProvider).trashDao;
