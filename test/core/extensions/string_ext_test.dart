import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/extensions/string_ext.dart';

void main() {
  group('StringWordCount.wordCount', () {
    test('empty string returns 0', () {
      expect(''.wordCount, 0);
    });

    test('whitespace-only string returns 0', () {
      expect('   \n\t  '.wordCount, 0);
    });

    test('single word returns 1', () {
      expect('hola'.wordCount, 1);
    });

    test('multiple words separated by single spaces', () {
      expect('hola mundo como estás'.wordCount, 4);
    });

    test('multiple spaces between words still counts correctly', () {
      expect('hola   mundo'.wordCount, 2);
    });

    test('leading and trailing whitespace is ignored', () {
      expect('  hola mundo  '.wordCount, 2);
    });

    test('newlines count as separators', () {
      expect('primera línea\nsegunda línea'.wordCount, 4);
    });

    test('tabs count as separators', () {
      expect('col1\tcol2\tcol3'.wordCount, 3);
    });

    test('unicode words count correctly', () {
      expect('こんにちは 世界'.wordCount, 2);
    });
  });

  group('StringWordCount.charCount', () {
    test('empty string returns 0', () {
      expect(''.charCount, 0);
    });

    test('whitespace is not counted', () {
      expect('h o l a'.charCount, 4);
    });

    test('newlines are not counted', () {
      expect('a\nb'.charCount, 2);
    });
  });

  group('StringWordCount.estimatedReadMinutes', () {
    test('empty string returns 1 (minimum)', () {
      expect(''.estimatedReadMinutes, 1);
    });

    test('200 words returns 1 minute', () {
      final text = List.generate(200, (_) => 'word').join(' ');
      expect(text.estimatedReadMinutes, 1);
    });

    test('400 words returns 2 minutes', () {
      final text = List.generate(400, (_) => 'word').join(' ');
      expect(text.estimatedReadMinutes, 2);
    });
  });

  group('StringWordCount.nullIfEmpty', () {
    test('empty string returns null', () {
      expect(''.nullIfEmpty, isNull);
    });

    test('whitespace-only returns null', () {
      expect('   '.nullIfEmpty, isNull);
    });

    test('non-empty string returns itself', () {
      expect('hola'.nullIfEmpty, 'hola');
    });
  });
}
