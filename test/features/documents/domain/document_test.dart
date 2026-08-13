import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/documents/domain/document.dart';

Document _doc({
  int wordCount = 0,
  int? targetWordCount,
  String title = '',
  bool isFavorite = false,
}) =>
    Document(
      id: 'test-id',
      title: title,
      content: '',
      plainText: '',
      wordCount: wordCount,
      charCount: 0,
      isFavorite: isFavorite,
      isDeleted: false,
      createdAt: DateTime(2026, 8, 12),
      updatedAt: DateTime(2026, 8, 12),
      targetWordCount: targetWordCount,
    );

void main() {
  group('Document.targetCompletion', () {
    test('returns 0.0 when no target set', () {
      expect(_doc().targetCompletion, 0.0);
    });

    test('returns 0.0 when target is 0', () {
      expect(_doc(targetWordCount: 0).targetCompletion, 0.0);
    });

    test('returns 0.5 at halfway', () {
      expect(_doc(wordCount: 250, targetWordCount: 500).targetCompletion, 0.5);
    });

    test('returns 1.0 at target', () {
      expect(_doc(wordCount: 500, targetWordCount: 500).targetCompletion, 1.0);
    });

    test('clamps to 1.0 when over target', () {
      expect(_doc(wordCount: 600, targetWordCount: 500).targetCompletion, 1.0);
    });
  });

  group('Document.displayTitle', () {
    test('returns title when non-empty', () {
      expect(_doc(title: 'Mi historia').displayTitle, 'Mi historia');
    });

    test('returns fallback for empty title', () {
      expect(_doc().displayTitle, 'Sin título');
    });

    test('returns fallback for whitespace-only title', () {
      expect(_doc(title: '   ').displayTitle, 'Sin título');
    });
  });

  group('Document.hasTarget', () {
    test('false when no target', () {
      expect(_doc().hasTarget, isFalse);
    });

    test('false when target is 0', () {
      expect(_doc(targetWordCount: 0).hasTarget, isFalse);
    });

    test('true when target > 0', () {
      expect(_doc(targetWordCount: 500).hasTarget, isTrue);
    });
  });
}
