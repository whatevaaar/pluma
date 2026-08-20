import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/editor/data/document_exporter.dart';

// Tests for DocumentExporter.deltaToMarkdown — the Delta-to-Markdown converter.
//
// Each test builds a minimal Delta JSON string (the format produced by _saveNow)
// and verifies the output matches the expected Markdown.

String _delta(List<Map<String, Object>> ops) {
  final opsJson = ops
      .map((op) {
        final parts = ['"insert":${_encodeValue(op['insert']!)}'];
        if (op.containsKey('attributes')) {
          parts.add('"attributes":${_encodeMap(op['attributes']! as Map)}');
        }
        return '{${parts.join(',')}}';
      })
      .join(',');
  return '{"ops":[$opsJson]}';
}

String _encodeValue(Object value) {
  if (value is String) {
    return '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';
  }
  return value.toString();
}

String _encodeMap(Map map) {
  final entries = map.entries
      .map((e) => '"${e.key}":${_encodeValue(e.value)}')
      .join(',');
  return '{$entries}';
}

void main() {
  group('deltaToMarkdown — invalid / empty input', () {
    test('empty string returns empty string', () {
      expect(DocumentExporter.deltaToMarkdown(''), isEmpty);
    });

    test('malformed JSON returns empty string', () {
      expect(DocumentExporter.deltaToMarkdown('{not valid json'), isEmpty);
    });

    test('JSON without ops key returns empty string', () {
      expect(DocumentExporter.deltaToMarkdown('{"data":[]}'), isEmpty);
    });
  });

  group('deltaToMarkdown — plain text', () {
    test('plain paragraph with trailing newline', () {
      final input = _delta([
        {'insert': 'Hola mundo\n'},
      ]);
      expect(DocumentExporter.deltaToMarkdown(input), equals('Hola mundo\n'));
    });

    test('two-op plain paragraph (text + newline op)', () {
      final input = _delta([
        {'insert': 'Texto normal'},
        {'insert': '\n'},
      ]);
      expect(DocumentExporter.deltaToMarkdown(input), equals('Texto normal\n'));
    });

    test('content without trailing newline is flushed without newline', () {
      final input = _delta([
        {'insert': 'sin salto final'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('sin salto final'),
      );
    });
  });

  group('deltaToMarkdown — inline formatting', () {
    test('bold text wraps with **', () {
      final input = _delta([
        {
          'insert': 'negrita',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('**negrita**\n'),
      );
    });

    test('italic text wraps with *', () {
      final input = _delta([
        {
          'insert': 'cursiva',
          'attributes': {'italic': true},
        },
        {'insert': '\n'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('*cursiva*\n'),
      );
    });

    test('bold+italic text wraps with ***', () {
      final input = _delta([
        {
          'insert': 'ambos',
          'attributes': {'bold': true, 'italic': true},
        },
        {'insert': '\n'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('***ambos***\n'),
      );
    });

    test('mixed plain and bold in same line', () {
      final input = _delta([
        {'insert': 'inicio '},
        {
          'insert': 'bold',
          'attributes': {'bold': true},
        },
        {'insert': ' fin\n'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('inicio **bold** fin\n'),
      );
    });
  });

  group('deltaToMarkdown — block elements', () {
    test('H1 header via separate newline op', () {
      final input = _delta([
        {'insert': 'Gran título'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('# Gran título\n'),
      );
    });

    test('H2 header via separate newline op', () {
      final input = _delta([
        {'insert': 'Subtítulo'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('## Subtítulo\n'),
      );
    });

    test('bullet list item', () {
      final input = _delta([
        {'insert': 'elemento'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('- elemento\n'),
      );
    });

    test('multiple bullet items', () {
      final input = _delta([
        {'insert': 'primero'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'segundo'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('- primero\n- segundo\n'),
      );
    });

    test('ordered list items are numbered sequentially', () {
      final input = _delta([
        {'insert': 'primero'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
        {'insert': 'segundo'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
        {'insert': 'tercero'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('1. primero\n2. segundo\n3. tercero\n'),
      );
    });

    test('ordered counter resets after a plain paragraph', () {
      final input = _delta([
        {'insert': 'primero'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
        {'insert': 'pausa\n'},
        {'insert': 'uno de nuevo'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
      ]);
      final result = DocumentExporter.deltaToMarkdown(input);
      expect(result, contains('1. primero'));
      expect(result, contains('1. uno de nuevo'));
    });

    test('ordered counter resets after an H1', () {
      final input = _delta([
        {'insert': 'primero'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
        {'insert': 'Nuevo capítulo'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
        {'insert': 'uno de nuevo'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'},
        },
      ]);
      final result = DocumentExporter.deltaToMarkdown(input);
      expect(result, contains('1. primero'));
      expect(result, contains('# Nuevo capítulo'));
      expect(result, contains('1. uno de nuevo'));
    });
  });

  group('deltaToMarkdown — mixed content', () {
    test('H1 followed by plain paragraph', () {
      final input = _delta([
        {'insert': 'Título'},
        {
          'insert': '\n',
          'attributes': {'header': 1},
        },
        {'insert': 'Texto normal\n'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('# Título\nTexto normal\n'),
      );
    });

    test('H2 then bullet list then plain paragraph', () {
      final input = _delta([
        {'insert': 'Sección'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
        {'insert': 'item'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'epílogo\n'},
      ]);
      expect(
        DocumentExporter.deltaToMarkdown(input),
        equals('## Sección\n- item\nepílogo\n'),
      );
    });
  });
}
