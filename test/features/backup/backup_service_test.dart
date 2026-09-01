import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/backup/data/backup_service.dart';
import 'package:pluma/features/backup/domain/backup_exceptions.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';

import '../../shared/fakes/fake_settings_repository.dart';

AppDatabase _makeDb() => AppDatabase(NativeDatabase.memory());

Future<void> _seed(AppDatabase db) async {
  final now = DateTime(2026);
  await db.projectsDao.upsert(
    ProjectsCompanion.insert(
      id: 'p1',
      name: 'Proyecto',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.documentsDao.insert(
    DocumentsCompanion.insert(
      id: 'd1',
      title: 'Uno',
      content: r'{"ops":[{"insert":"hola\n"}]}',
      plainText: 'hola',
      projectId: const Value('p1'),
      createdAt: now,
      updatedAt: now,
    ),
  );
  // A soft-deleted document should survive the round-trip.
  await db.documentsDao.insert(
    DocumentsCompanion.insert(
      id: 'd2',
      title: 'Borrado',
      content: r'{"ops":[{"insert":"x\n"}]}',
      plainText: 'x',
      isDeleted: const Value(true),
      deletedAt: Value(now),
      createdAt: now,
      updatedAt: now,
    ),
  );
  await db.statisticsDao.upsertToday(
    dateKey: '2026-01-01',
    wordsDelta: 42,
    minutes: 5,
  );
}

void main() {
  test('buildBackup captures projects, documents, stats and settings',
      () async {
    final db = _makeDb();
    addTearDown(db.close);
    await _seed(db);
    final service = BackupService(
      db.backupDao,
      FakeSettingsRepository(
        initial: const AppSettings(writingTheme: WritingTheme.sepia),
      ),
    );

    final backup = await service.buildBackup(appVersion: 'v9');

    expect(backup['format'], 'pluma-backup');
    expect(backup['version'], 1);
    expect((backup['projects'] as List).length, 1);
    expect((backup['documents'] as List).length, 2); // includes the deleted one
    expect((backup['dailyStats'] as List).length, 1);
    expect(
      (backup['settings'] as Map)['writingTheme'],
      'sepia',
    );
  });

  test('restore replaces the library and settings from a backup', () async {
    // Source DB → build a backup.
    final source = _makeDb();
    addTearDown(source.close);
    await _seed(source);
    final sourceService = BackupService(
      source.backupDao,
      FakeSettingsRepository(
        initial: const AppSettings(writingTheme: WritingTheme.forest),
      ),
    );
    final backup = await sourceService.buildBackup(appVersion: 'v9');

    // Fresh target DB with pre-existing junk that must be wiped.
    final target = _makeDb();
    addTearDown(target.close);
    await target.documentsDao.insert(
      DocumentsCompanion.insert(
        id: 'junk',
        title: 'Basura',
        content: r'{"ops":[{"insert":"\n"}]}',
        plainText: '',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      ),
    );
    final targetSettings = FakeSettingsRepository();
    final targetService = BackupService(target.backupDao, targetSettings);

    await targetService.restore(backup);

    final docs = await target.backupDao.getAllDocuments();
    final projects = await target.backupDao.getAllProjects();
    final stats = await target.backupDao.getAllDailyStats();
    expect(docs.map((d) => d.id).toSet(), {'d1', 'd2'}); // junk gone
    expect(projects.single.id, 'p1');
    expect(stats.single.wordsWritten, 42);
    expect(
      (await targetSettings.getSettings()).writingTheme,
      WritingTheme.forest,
    );
  });

  test('restore repopulates the FTS index', () async {
    final source = _makeDb();
    addTearDown(source.close);
    await _seed(source);
    final backup = await BackupService(
      source.backupDao,
      FakeSettingsRepository(),
    ).buildBackup(appVersion: 'v9');

    final target = _makeDb();
    addTearDown(target.close);
    await BackupService(target.backupDao, FakeSettingsRepository())
        .restore(backup);

    // Query the FTS virtual table directly (the DAO's searchFullText has an
    // unrelated pre-existing deserialization bug). A match proves the AFTER
    // INSERT triggers fired during the bulk restore.
    final hits = await target.customSelect(
      'SELECT d.id AS id FROM documents d '
      'INNER JOIN documents_fts fts ON d.rowid = fts.rowid '
      "WHERE documents_fts MATCH 'hola'",
      readsFrom: {target.documents},
    ).get();
    expect(hits.map((r) => r.data['id']), contains('d1'));
  });

  group('parseBackup', () {
    final service = BackupService(
      _makeDb().backupDao,
      FakeSettingsRepository(),
    );

    test('accepts a valid backup and reports counts', () {
      const raw =
          '{"format":"pluma-backup","version":1,"projects":[{}],'
          '"documents":[{},{}]}';
      final summary = service.parseBackup(raw);
      expect(summary.projectCount, 1);
      expect(summary.documentCount, 2);
    });

    test('rejects a non-Pluma file', () {
      expect(
        () => service.parseBackup('{"format":"otra-cosa","version":1}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a newer backup version', () {
      expect(
        () => service.parseBackup('{"format":"pluma-backup","version":99}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects invalid JSON', () {
      expect(
        () => service.parseBackup('not json'),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
