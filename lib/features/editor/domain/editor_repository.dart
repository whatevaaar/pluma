import 'package:pluma/features/documents/domain/document.dart';

abstract interface class EditorRepository {
  Future<Document?> load(String documentId);

  /// Saves the current state of the document.
  ///
  /// [wordsDelta] is the net change in words since the last save —
  /// used by StatisticsRepository to credit writing effort correctly.
  Future<void> save({
    required String documentId,
    required String title,
    required String content,
    required String plainText,
    required int wordCount,
    required int charCount,
    int wordsDelta = 0,
  });
}
