import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression guard for the serialization bug fixed in editor_notifier.dart.
//
// The original code called toDelta().toJson().toString(), which uses Dart's
// List.toString() and produces invalid JSON: [{insert: text}] (no quotes
// around keys or values). _buildController then called jsonDecode() on it,
// which threw a FormatException, and the catch block silently returned an
// empty QuillController — losing all document content on every load.
//
// The fix: jsonEncode({'ops': toDelta().toJson()}) → {"ops":[{"insert":"..."}]}

Document _load(String deltaJson) {
  final raw =
      deltaJson.isNotEmpty ? deltaJson : r'{"ops":[{"insert":"\n"}]}';
  final ops =
      (jsonDecode(raw) as Map<String, dynamic>)['ops'] as List<dynamic>;
  return Document.fromJson(ops);
}

String _save(Document doc) =>
    jsonEncode({'ops': doc.toDelta().toJson()});

void main() {
  group('Delta serialization — regression guard', () {
    test('old broken format (List.toString) is not valid JSON', () {
      // Documents why the bug existed: Dart's List.toString() on a list of
      // Maps produces [{insert: hola}] — string keys without quotes → not JSON.
      final doc = Document();
      doc.insert(0, 'hola');
      final brokenFormat = doc.toDelta().toJson().toString();
      expect(() => jsonDecode(brokenFormat), throwsFormatException);
    });

    test('correct format (jsonEncode with ops wrapper) is valid JSON', () {
      final doc = Document();
      doc.insert(0, 'hola');
      final correct = _save(doc);
      expect(() => jsonDecode(correct), returnsNormally);
    });

    test('saved JSON has top-level "ops" key containing a list', () {
      final doc = Document();
      doc.insert(0, 'test');
      final decoded = jsonDecode(_save(doc)) as Map<String, dynamic>;
      expect(decoded.containsKey('ops'), isTrue);
      expect(decoded['ops'], isA<List>());
    });

    test('ops list contains map entries with an "insert" key', () {
      final doc = Document();
      doc.insert(0, 'contenido');
      final ops = (jsonDecode(_save(doc)) as Map<String, dynamic>)['ops']
          as List<dynamic>;
      expect(ops, isNotEmpty);
      expect(
        ops.every((op) => op is Map && (op as Map).containsKey('insert')),
        isTrue,
      );
    });
  });

  group('Delta save/load round-trip', () {
    test('plain text round-trips correctly', () {
      const text = 'El veloz murciélago hindú comía feliz cardillo y kiwi';
      final original = Document()..insert(0, text);
      final restored = _load(_save(original));
      // Quill always appends a trailing newline — trim before comparing.
      expect(restored.toPlainText().trim(), equals(text));
    });

    test('multi-paragraph document preserves all paragraphs', () {
      const para1 = 'Primer párrafo';
      const para2 = 'Segundo párrafo';
      final original = Document()..insert(0, '$para1\n$para2');
      final restored = _load(_save(original));
      final plain = restored.toPlainText();
      expect(plain, contains(para1));
      expect(plain, contains(para2));
    });

    test('empty content falls back to minimal empty document', () {
      // An empty string content triggers the fallback in _buildController.
      final doc = _load('');
      // The fallback is {"ops":[{"insert":"\n"}]} — a single newline.
      expect(doc.toPlainText(), equals('\n'));
    });

    test('repeated save/load cycle is idempotent', () {
      const text = 'Texto de prueba';
      final original = Document()..insert(0, text);

      final json1 = _save(original);
      final doc2 = _load(json1);
      final json2 = _save(doc2);
      final doc3 = _load(json2);

      expect(doc3.toPlainText().trim(), equals(text));
    });

    test('unicode content survives round-trip', () {
      const text = '日本語のテキスト 🦋 émojis et accents';
      final original = Document()..insert(0, text);
      final restored = _load(_save(original));
      expect(restored.toPlainText().trim(), equals(text));
    });

    test('long document survives round-trip without truncation', () {
      final longText = List.generate(500, (i) => 'word$i').join(' ');
      final original = Document()..insert(0, longText);
      final restored = _load(_save(original));
      expect(restored.toPlainText().trim(), equals(longText));
    });
  });
}
