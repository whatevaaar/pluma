import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_version.freezed.dart';

/// A point-in-time snapshot of a document's content.
@freezed
abstract class DocumentVersion with _$DocumentVersion {
  const factory DocumentVersion({
    required String id,
    required String documentId,
    // Quill Delta JSON snapshot
    required String content,
    required String plainText,
    required int wordCount,
    required DateTime createdAt,
    // Why the snapshot was taken: 'session' | 'auto' | 'manual' | 'pre-restore'
    String? reason,
  }) = _DocumentVersion;

  const DocumentVersion._();

  /// Human-readable label for [reason], shown as a badge in the history list.
  String get reasonLabel => switch (reason) {
        'manual' => 'Manual',
        'session' => 'Fin de sesión',
        'pre-restore' => 'Antes de restaurar',
        'auto' => 'Automática',
        _ => 'Automática',
      };
}
