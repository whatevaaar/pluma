import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pluma/features/documents/data/documents_dao.dart';
import 'package:pluma/features/documents/data/projects_dao.dart';
import 'package:pluma/features/statistics/data/statistics_dao.dart';
import 'package:pluma/features/trash/data/trash_dao.dart';
import 'package:pluma/features/versions/data/versions_dao.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

@DataClassName('ProjectRow')
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().nullable()(); // hex, e.g. "#5C7AEA"
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().nullable().references(Projects, #id)();
  TextColumn get title => text().withLength(min: 0, max: 500)();
  // Quill Delta JSON — the authoritative content format
  TextColumn get content => text()();
  // Derived plain text kept in sync on every save — used for FTS and word count
  // without deserializing Delta on every read
  TextColumn get plainText => text()();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  IntColumn get charCount => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get targetWordCount => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class WritingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  IntColumn get wordsWritten => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Snapshot upserted at the end of each session — drives heatmap and streak
// calc.
class DailyStats extends Table {
  // "YYYY-MM-DD" — serves as primary key and heatmap data key
  TextColumn get date => text()();
  IntColumn get wordsWritten => integer().withDefault(const Constant(0))();
  IntColumn get minutesWritten => integer().withDefault(const Constant(0))();
  IntColumn get sessionsCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {date};
}

class UserGoals extends Table {
  TextColumn get id => text()();
  IntColumn get dailyWordTarget =>
      integer().withDefault(const Constant(500))();
  BoolColumn get streakReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  // "HH:mm" — null means no reminder
  TextColumn get reminderTime => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Point-in-time snapshots of a document's content, so edits made under the
// silent 3s autosave are recoverable. Written on a throttled schedule and at
// session end (see EditorNotifier). Pruned to the newest N per document.
@DataClassName('DocumentVersionRow')
class DocumentVersions extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id)();
  // Quill Delta JSON snapshot — same format as Documents.content
  TextColumn get content => text()();
  // Derived plain text — used for the preview and word count without decoding
  TextColumn get plainText => text()();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  // 'session' | 'auto' | 'manual' | 'pre-restore'
  TextColumn get reason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    Projects,
    Documents,
    WritingSessions,
    DailyStats,
    UserGoals,
    DocumentVersions,
  ],
  daos: [DocumentsDao, ProjectsDao, StatisticsDao, TrashDao, VersionsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createVersionsIndex();
          // FTS5 virtual table for full-text search over documents.
          // Using content= to keep the index in sync with the documents table.
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts
            USING fts5(title, plain_text, content=documents, content_rowid=rowid)
          ''');
          // Triggers to keep FTS index up to date.
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS documents_ai
            AFTER INSERT ON documents BEGIN
              INSERT INTO documents_fts(rowid, title, plain_text)
              VALUES (new.rowid, new.title, new.plain_text);
            END
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS documents_ad
            AFTER DELETE ON documents BEGIN
              INSERT INTO documents_fts(documents_fts, rowid, title, plain_text)
              VALUES ('delete', old.rowid, old.title, old.plain_text);
            END
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS documents_au
            AFTER UPDATE ON documents BEGIN
              INSERT INTO documents_fts(documents_fts, rowid, title, plain_text)
              VALUES ('delete', old.rowid, old.title, old.plain_text);
              INSERT INTO documents_fts(rowid, title, plain_text)
              VALUES (new.rowid, new.title, new.plain_text);
            END
          ''');
        },
        onUpgrade: (m, from, to) async {
          // Each migration step is explicit — never DROP, always ADD/ALTER.
          // Add new steps here as schemaVersion increments.
          if (from < 2) {
            await m.createTable(documentVersions);
            await _createVersionsIndex();
          }
        },
      );

  // Index for listing/pruning a document's versions newest-first.
  Future<void> _createVersionsIndex() => customStatement(
        'CREATE INDEX IF NOT EXISTS idx_document_versions_doc_created '
        'ON document_versions (document_id, created_at)',
      );
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pluma.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Overridden in main.dart with the real AppDatabase instance.
/// Tests override with an in-memory database.
@riverpod
AppDatabase appDatabase(Ref ref) => throw UnimplementedError(
      'appDatabaseProvider must be overridden in ProviderScope',
    );
