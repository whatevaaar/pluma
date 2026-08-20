import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/documents/data/documents_dao.dart';
import 'package:pluma/features/editor/data/editor_repository_impl.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

Future<void> _createDoc(
  DocumentsDao dao,
  String id, {
  String title = '',
  String content = r'{"ops":[{"insert":"\n"}]}',
}) async {
  final now = DateTime(2026, 1, 1);
  await dao.insert(
    DocumentsCompanion.insert(
      id: id,
      title: title,
      content: content,
      plainText: '',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late DocumentsDao dao;
  late EditorRepositoryImpl repo;

  setUp(() {
    db = _makeDb();
    dao = db.documentsDao;
    repo = EditorRepositoryImpl(dao);
  });

  tearDown(() => db.close());

  group('EditorRepository.save — persistence regression', () {
    // This exact scenario was broken: save() used insertOnConflictUpdate with
    // an absent createdAt, which failed Drift's isInserting validation and
    // threw silently, leaving every document blank after reload.
    test('title persists after save', () async {
      await _createDoc(dao, 'doc-1');

      await repo.save(
        documentId: 'doc-1',
        title: 'Mi primer ensayo',
        content: r'{"ops":[{"insert":"\n"}]}',
        plainText: '',
        wordCount: 0,
        charCount: 0,
      );

      final loaded = await repo.load('doc-1');
      expect(loaded, isNotNull);
      expect(loaded!.title, 'Mi primer ensayo');
    });

    test('content persists after save', () async {
      await _createDoc(dao, 'doc-2');
      const delta = r'{"ops":[{"insert":"Hola mundo\n"}]}';

      await repo.save(
        documentId: 'doc-2',
        title: 'Draft',
        content: delta,
        plainText: 'Hola mundo',
        wordCount: 2,
        charCount: 10,
      );

      final loaded = await repo.load('doc-2');
      expect(loaded!.content, delta);
      expect(loaded.wordCount, 2);
    });

    test('createdAt is not clobbered by save', () async {
      final created = DateTime(2025, 6, 15, 9, 30);
      final now = created;
      await dao.insert(
        DocumentsCompanion.insert(
          id: 'doc-3',
          title: '',
          content: r'{"ops":[{"insert":"\n"}]}',
          plainText: '',
          createdAt: created,
          updatedAt: now,
        ),
      );

      await repo.save(
        documentId: 'doc-3',
        title: 'Updated',
        content: r'{"ops":[{"insert":"text\n"}]}',
        plainText: 'text',
        wordCount: 1,
        charCount: 4,
      );

      final row = await dao.findById('doc-3');
      expect(row, isNotNull);
      expect(
        row!.createdAt.millisecondsSinceEpoch,
        created.millisecondsSinceEpoch,
        reason: 'save() must not touch createdAt',
      );
    });

    test('multiple saves accumulate correctly', () async {
      await _createDoc(dao, 'doc-4');

      await repo.save(
        documentId: 'doc-4',
        title: 'Borrador',
        content: r'{"ops":[{"insert":"Primera línea\n"}]}',
        plainText: 'Primera línea',
        wordCount: 2,
        charCount: 13,
      );

      await repo.save(
        documentId: 'doc-4',
        title: 'Definitivo',
        content: r'{"ops":[{"insert":"Primera línea\nSegunda línea\n"}]}',
        plainText: 'Primera línea\nSegunda línea',
        wordCount: 4,
        charCount: 27,
      );

      final loaded = await repo.load('doc-4');
      expect(loaded!.title, 'Definitivo');
      expect(loaded.wordCount, 4);
      expect(loaded.charCount, 27);
    });

    test('save with targetWordCount persists goal', () async {
      await _createDoc(dao, 'doc-5');

      await repo.save(
        documentId: 'doc-5',
        title: 'Con meta',
        content: r'{"ops":[{"insert":"\n"}]}',
        plainText: '',
        wordCount: 0,
        charCount: 0,
        targetWordCount: 1000,
      );

      final loaded = await repo.load('doc-5');
      expect(loaded!.targetWordCount, 1000);
    });

    test('save without targetWordCount sets goal to null', () async {
      await _createDoc(dao, 'doc-6');

      await repo.save(
        documentId: 'doc-6',
        title: 'Sin meta',
        content: r'{"ops":[{"insert":"\n"}]}',
        plainText: '',
        wordCount: 0,
        charCount: 0,
      );

      final loaded = await repo.load('doc-6');
      expect(loaded!.targetWordCount, isNull);
    });
  });
}
