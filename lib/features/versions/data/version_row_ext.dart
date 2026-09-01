import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/versions/domain/document_version.dart';

extension DocumentVersionRowX on DocumentVersionRow {
  DocumentVersion toDomain() => DocumentVersion(
        id: id,
        documentId: documentId,
        content: content,
        plainText: plainText,
        wordCount: wordCount,
        createdAt: createdAt,
        reason: reason,
      );
}
