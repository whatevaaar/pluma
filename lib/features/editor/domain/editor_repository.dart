import 'package:pluma/features/documents/domain/document.dart';

abstract interface class EditorRepository {
  Future<Document?> load(String documentId);

  Future<void> save({
    required String documentId,
    required String title,
    required String content,
    required String plainText,
    required int wordCount,
    required int charCount,
  });
}
