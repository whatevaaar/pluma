import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/documents/data/documents_dao.dart';
import 'package:pluma/features/trash/data/trash_dao.dart';
import 'package:pluma/features/versions/data/versions_dao.dart';
import 'package:pluma/features/versions/data/versions_repository_impl.dart';

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

Future<void> _createDoc(DocumentsDao dao, String id) async {
  final now = DateTime(2026);
  await dao.insert(
    DocumentsCompanion.insert(
      id: id,
      title: '',
      content: r'{"ops":[{"insert":"\n"}]}',
      plainText: '',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

/// Inserts a version dated day [day] of Jan 2026 — [day] is a variable so
/// callers stay terse and avoid the redundant-DateTime-args lint.
Future<void> _insertVersion(
  VersionsDao dao,
  String docId, {
  required String id,
  required int day,
}) {
  return dao.insert(
    DocumentVersionsCompanion(
      id: Value(id),
      documentId: Value(docId),
      content: Value('{"ops":[{"insert":"$id\\n"}]}'),
      plainText: Value(id),
      wordCount: const Value(1),
      createdAt: Value(DateTime(2026, 1, day)),
      reason: const Value('auto'),
    ),
  );
}

void main() {
  late AppDatabase db;
  late VersionsDao versionsDao;
  late DocumentsDao documentsDao;
  late TrashDao trashDao;
  late VersionsRepositoryImpl repo;

  setUp(() {
    db = _makeDb();
    versionsDao = db.versionsDao;
    documentsDao = db.documentsDao;
    trashDao = db.trashDao;
    repo = VersionsRepositoryImpl(versionsDao);
  });

  tearDown(() => db.close());

  group('VersionsDao', () {
    test('watchForDocument returns versions newest-first', () async {
      await _createDoc(documentsDao, 'doc-1');
      await _insertVersion(versionsDao, 'doc-1', id: 'v1', day: 1);
      await _insertVersion(versionsDao, 'doc-1', id: 'v2', day: 2);
      await _insertVersion(versionsDao, 'doc-1', id: 'v3', day: 3);

      final rows = await versionsDao.watchForDocument('doc-1').first;

      expect(rows.map((r) => r.id).toList(), ['v3', 'v2', 'v1']);
    });

    test('pruneOldest keeps only the newest N', () async {
      await _createDoc(documentsDao, 'doc-1');
      for (var i = 1; i <= 5; i++) {
        await _insertVersion(versionsDao, 'doc-1', id: 'v$i', day: i);
      }

      await versionsDao.pruneOldest('doc-1', keep: 2);

      final rows = await versionsDao.watchForDocument('doc-1').first;
      expect(rows.map((r) => r.id).toList(), ['v5', 'v4']);
    });

    test('countForDocument counts only that document', () async {
      await _createDoc(documentsDao, 'doc-1');
      await _createDoc(documentsDao, 'doc-2');
      await _insertVersion(versionsDao, 'doc-1', id: 'v1', day: 1);
      await _insertVersion(versionsDao, 'doc-2', id: 'v2', day: 1);

      expect(await versionsDao.countForDocument('doc-1'), 1);
    });
  });

  group('VersionsRepository', () {
    test('snapshot inserts a version and prunes to keep', () async {
      await _createDoc(documentsDao, 'doc-1');
      // Seed 3 older versions.
      for (var i = 1; i <= 3; i++) {
        await _insertVersion(versionsDao, 'doc-1', id: 'seed$i', day: i);
      }

      await repo.snapshot(
        documentId: 'doc-1',
        content: r'{"ops":[{"insert":"nuevo\n"}]}',
        plainText: 'nuevo',
        wordCount: 1,
        reason: 'manual',
        keep: 2,
      );

      final versions = await repo.watchForDocument('doc-1').first;
      expect(versions.length, 2);
      // The just-created snapshot (now) is newest, so it survives pruning.
      expect(versions.first.reason, 'manual');
      expect(versions.first.plainText, 'nuevo');
    });
  });

  group('Cascade delete of versions', () {
    test('deletePermanently removes the document versions', () async {
      await _createDoc(documentsDao, 'doc-1');
      await _insertVersion(versionsDao, 'doc-1', id: 'v1', day: 1);
      await _insertVersion(versionsDao, 'doc-1', id: 'v2', day: 2);

      await trashDao.deletePermanently('doc-1');

      expect(await versionsDao.countForDocument('doc-1'), 0);
    });

    test('emptyTrash removes orphaned versions', () async {
      await _createDoc(documentsDao, 'doc-1');
      await _insertVersion(versionsDao, 'doc-1', id: 'v1', day: 1);
      await trashDao.softDelete('doc-1');

      await trashDao.emptyTrash();

      expect(await versionsDao.countForDocument('doc-1'), 0);
    });
  });
}
