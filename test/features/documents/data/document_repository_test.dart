import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/documents/data/document_repository_impl.dart';

// Regression tests against the REAL Drift database. The fake repository used by
// the library-notifier tests cannot catch this class of bug: rename() and
// softDelete() previously used insertOnConflictUpdate with a partial companion,
// which fails Drift's isInserting validation (title/content/createdAt absent)
// and throws silently — so "Renombrar" and "Mover a papelera" did nothing.
void main() {
  late AppDatabase db;
  late DocumentRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DocumentRepositoryImpl(db.documentsDao, db.projectsDao);
  });

  tearDown(() => db.close());

  test('softDelete marks the document as deleted', () async {
    final id = await repo.create();

    await repo.softDelete(id);

    final doc = await repo.findById(id);
    expect(doc, isNotNull);
    expect(doc!.isDeleted, isTrue);
    expect(doc.deletedAt, isNotNull);
  });

  test('rename updates the title', () async {
    final id = await repo.create();

    await repo.rename(id, 'Mi título');

    final doc = await repo.findById(id);
    expect(doc?.title, 'Mi título');
  });

  test('rename does not clobber content or createdAt', () async {
    final id = await repo.create();
    final before = await repo.findById(id);

    await repo.rename(id, 'Nuevo nombre');

    final after = await repo.findById(id);
    expect(after!.content, before!.content);
    expect(
      after.createdAt.millisecondsSinceEpoch,
      before.createdAt.millisecondsSinceEpoch,
    );
  });

  test('createProject persists a folder that can be fetched back', () async {
    final id = await repo.createProject('Poemas');

    final project = await repo.findProjectById(id);
    expect(project?.name, 'Poemas');
  });

  // Regression: searchFullText mapped FTS rows with DocumentRow.fromJson
  // (camelCase keys) over snake_case DB columns, so any match threw
  // "type 'Null' is not a subtype of type 'String'".
  test('search returns matching documents without crashing', () async {
    await db.documentsDao.insert(
      DocumentsCompanion.insert(
        id: 'doc-search',
        title: 'Nota',
        content: r'{"ops":[{"insert":"ballena azul\n"}]}',
        plainText: 'ballena azul',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    final results = await repo.search('ballena');

    expect(results.map((d) => d.id), contains('doc-search'));
    expect(results.single.plainText, 'ballena azul');
  });
}
