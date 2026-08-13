import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';

@freezed
abstract class Document with _$Document {
  const factory Document({
    required String id,
    required String title,
    // Quill Delta JSON — authoritative format
    required String content,
    // Plain text derived from content — kept in sync by the repository
    required String plainText,
    required int wordCount,
    required int charCount,
    required bool isFavorite,
    required bool isDeleted,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? projectId,
    DateTime? deletedAt,
    int? targetWordCount,
  }) = _Document;

  const Document._();

  /// Completion ratio toward [targetWordCount], 0.0–1.0.
  /// Returns 0.0 if no target is set.
  double get targetCompletion {
    final target = targetWordCount;
    if (target == null || target <= 0) return 0;
    return (wordCount / target).clamp(0.0, 1.0);
  }

  bool get hasTarget => targetWordCount != null && targetWordCount! > 0;

  /// Returns a non-empty title for display, falling back to a default label.
  String get displayTitle => title.trim().isEmpty ? 'Sin título' : title;
}
