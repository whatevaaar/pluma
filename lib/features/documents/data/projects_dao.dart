import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'projects_dao.g.dart';

@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDaoMixin {
  ProjectsDao(super.attachedDatabase);

  Stream<List<ProjectRow>> watchAll({bool includeArchived = false}) {
    final query = select(projects);
    if (!includeArchived) {
      query.where((p) => p.isArchived.equals(false));
    }
    query.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch();
  }

  Future<ProjectRow?> findById(String id) {
    return (select(projects)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsert(ProjectsCompanion companion) {
    return into(projects).insertOnConflictUpdate(companion);
  }

  Future<void> archive(String id) {
    return (update(projects)..where((p) => p.id.equals(id))).write(
      const ProjectsCompanion(isArchived: Value(true)),
    );
  }
}

@riverpod
ProjectsDao projectsDao(Ref ref) => ref.watch(appDatabaseProvider).projectsDao;
