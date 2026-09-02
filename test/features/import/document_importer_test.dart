import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/editor/data/document_exporter.dart';
import 'package:pluma/features/import/data/document_importer.dart';

List<dynamic> _ops(String content) =>
    (jsonDecode(content) as Map<String, dynamic>)['ops'] as List<dynamic>;

void main() {
  group('parseImportedFile — title', () {
    test('derives the title from the filename without extension', () {
      final doc = parseImportedFile(filename: 'Mi Ensayo.txt', raw: 'hola');
      expect(doc.title, 'Mi Ensayo');
    });

    test('handles paths and falls back when blank', () {
      expect(
        parseImportedFile(filename: '/tmp/notas/diario.md', raw: 'x').title,
        'diario',
      );
      expect(
        parseImportedFile(filename: '.txt', raw: 'x').title,
        'Documento importado',
      );
    });
  });

  group('parseImportedFile — plain text (.txt)', () {
    test('imports content verbatim and counts words', () {
      final doc = parseImportedFile(
        filename: 'nota.txt',
        raw: 'Primera línea\nSegunda línea',
      );
      expect(doc.plainText, 'Primera línea\nSegunda línea');
      expect(doc.wordCount, 4);
      // Single insert op ending in a newline.
      expect(_ops(doc.content).length, 1);
    });

    test('does not treat markdown markers specially in .txt', () {
      final doc = parseImportedFile(filename: 'n.txt', raw: '# No es título');
      expect(doc.plainText, '# No es título');
    });
  });

  group('parseImportedFile — markdown (.md)', () {
    test('converts headings and lists to block attributes', () {
      final doc = parseImportedFile(
        filename: 'doc.md',
        raw: '# Título\n\n- uno\n- dos',
      );
      final ops = _ops(doc.content).cast<Map<String, dynamic>>();
      bool isNewlineWith(Map<String, dynamic> o, String key, Object value) =>
          o['insert'] == '\n' && (o['attributes'] as Map?)?[key] == value;

      expect(ops.any((o) => isNewlineWith(o, 'header', 1)), isTrue);
      expect(
        ops.where((o) => isNewlineWith(o, 'list', 'bullet')).length,
        2,
      );
      expect(doc.plainText, contains('Título'));
      expect(doc.plainText, contains('uno'));
    });

    test('parses inline bold and italic', () {
      final doc = parseImportedFile(
        filename: 'd.md',
        raw: 'un **texto** en *cursiva*',
      );
      final ops = _ops(doc.content).cast<Map<String, dynamic>>();
      bool hasInsertWithAttr(String text, String attr) => ops.any(
            (o) =>
                o['insert'] == text && (o['attributes'] as Map?)?[attr] == true,
          );

      expect(hasInsertWithAttr('texto', 'bold'), isTrue);
      expect(hasInsertWithAttr('cursiva', 'italic'), isTrue);
    });

    test('round-trips markdown through export', () {
      const md = '# Título\nun **texto** normal\n- item';
      final doc = parseImportedFile(filename: 'r.md', raw: md);
      final backToMd = DocumentExporter.deltaToMarkdown(doc.content);
      expect(backToMd.trim(), md.trim());
    });
  });
}
