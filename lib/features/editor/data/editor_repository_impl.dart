import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../documents/data/documents_dao.dart';
import '../../documents/domain/document.dart';
import '../domain/editor_repository.dart';

part 'editor_repository_impl.g.dart';

class EditorRepositoryImpl implements EditorRepository {
  EditorRepositoryImpl(this._dao, this._db);

  final DocumentsDao _dao;
  final AppDatabase _db;

  @override
  Future<Document?> load(String documentId) async {
    final row = await _dao.findById(documentId);
    if (row == null) return null;
    return Document(
      id: row.id,
      projectId: row.projectId,
      title: row.title,
      content: row.content,
      plainText: row.plainText,
      wordCount: row.wordCount,
      charCount: row.charCount,
      isFavorite: row.isFavorite,
      isDeleted: row.isDeleted,
      deletedAt: row.deletedAt,
      targetWordCount: row.targetWordCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> save({
    required String documentId,
    required String title,
    required String content,
    required String plainText,
    required int wordCount,
    required int charCount,
    int wordsDelta = 0,
  }) {
    return _dao.upsert(
      DocumentsCompanion(
        id: Value(documentId),
        title: Value(title),
        content: Value(content),
        plainText: Value(plainText),
        wordCount: Value(wordCount),
        charCount: Value(charCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

@riverpod
EditorRepository editorRepository(Ref ref) => EditorRepositoryImpl(
      ref.watch(documentsDaoProvider),
      ref.watch(appDatabaseProvider),
    );
