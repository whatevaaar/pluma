import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/documents/domain/document.dart';

extension DocumentRowX on DocumentRow {
  Document toDomain() => Document(
        id: id,
        projectId: projectId,
        title: title,
        content: content,
        plainText: plainText,
        wordCount: wordCount,
        charCount: charCount,
        isFavorite: isFavorite,
        isDeleted: isDeleted,
        deletedAt: deletedAt,
        targetWordCount: targetWordCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
