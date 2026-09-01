import 'package:pluma/features/versions/domain/document_version.dart';

/// Stores and retrieves point-in-time snapshots of document content.
abstract class VersionsRepository {
  /// Newest-first stream of all versions for [documentId].
  Stream<List<DocumentVersion>> watchForDocument(String documentId);

  Future<DocumentVersion?> findById(String id);

  /// Records a new snapshot, then prunes to the newest [keep] for the document.
  Future<void> snapshot({
    required String documentId,
    required String content,
    required String plainText,
    required int wordCount,
    String? reason,
    int keep,
  });

  Future<void> deleteById(String id);
}
