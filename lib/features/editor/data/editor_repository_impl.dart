import 'package:drift/drift.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/documents/data/document_row_ext.dart';
import 'package:pluma/features/documents/data/documents_dao.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/editor/domain/editor_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_repository_impl.g.dart';

class EditorRepositoryImpl implements EditorRepository {
  EditorRepositoryImpl(this._dao);

  final DocumentsDao _dao;

  @override
  Future<Document?> load(String documentId) async {
    final row = await _dao.findById(documentId);
    return row?.toDomain();
  }

  @override
  Future<void> save({
    required String documentId,
    required String title,
    required String content,
    required String plainText,
    required int wordCount,
    required int charCount,
    int? targetWordCount,
  }) {
    return _dao.upsert(
      DocumentsCompanion(
        id: Value(documentId),
        title: Value(title),
        content: Value(content),
        plainText: Value(plainText),
        wordCount: Value(wordCount),
        charCount: Value(charCount),
        targetWordCount: Value(targetWordCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

@riverpod
EditorRepository editorRepository(Ref ref) =>
    EditorRepositoryImpl(ref.watch(documentsDaoProvider));
