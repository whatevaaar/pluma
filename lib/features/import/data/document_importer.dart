import 'dart:convert';

import 'package:pluma/core/extensions/string_ext.dart';

/// A document parsed from an imported file, ready to persist.
class ImportedDocument {
  const ImportedDocument({
    required this.title,
    required this.content,
    required this.plainText,
    required this.wordCount,
    required this.charCount,
  });

  final String title;
  // Quill Delta JSON — the authoritative content format.
  final String content;
  final String plainText;
  final int wordCount;
  final int charCount;
}

/// Parses a `.txt` or `.md` file into an [ImportedDocument]. Markdown gets a
/// lightweight conversion (headings, lists, bold/italic) symmetric to the
/// exporter; plain text is imported verbatim. Never throws — malformed input
/// degrades to plain paragraphs.
ImportedDocument parseImportedFile({
  required String filename,
  required String raw,
}) {
  final lower = filename.toLowerCase();
  final isMarkdown = lower.endsWith('.md') || lower.endsWith('.markdown');
  final ops = isMarkdown ? _markdownToOps(raw) : _plainToOps(raw);

  final plain = ops.map((o) => o['insert']! as String).join();
  final trimmed = plain.replaceAll(RegExp(r'\n$'), '');

  return ImportedDocument(
    title: _titleFromFilename(filename),
    content: jsonEncode({'ops': ops}),
    plainText: trimmed,
    wordCount: trimmed.wordCount,
    charCount: trimmed.charCount,
  );
}

String _titleFromFilename(String filename) {
  final base = filename.split(RegExp(r'[/\\]')).last;
  final withoutExt = base.contains('.')
      ? base.substring(0, base.lastIndexOf('.'))
      : base;
  final title = withoutExt.trim();
  return title.isEmpty ? 'Documento importado' : title;
}

List<Map<String, dynamic>> _plainToOps(String text) {
  final normalized = text.replaceAll('\r\n', '\n');
  final withNewline = normalized.endsWith('\n') ? normalized : '$normalized\n';
  return [
    {'insert': withNewline},
  ];
}

List<Map<String, dynamic>> _markdownToOps(String markdown) {
  final ops = <Map<String, dynamic>>[];
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');

  // A trailing newline yields a spurious empty final element — drop it so the
  // import doesn't gain a blank paragraph.
  if (lines.length > 1 && lines.last.isEmpty) lines.removeLast();

  for (final line in lines) {
    var text = line;
    Map<String, dynamic>? blockAttrs;

    if (line.startsWith('# ')) {
      text = line.substring(2);
      blockAttrs = {'header': 1};
    } else if (line.startsWith('## ')) {
      text = line.substring(3);
      blockAttrs = {'header': 2};
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      text = line.substring(2);
      blockAttrs = {'list': 'bullet'};
    } else {
      final ordered = RegExp(r'^\d+\.\s').firstMatch(line);
      if (ordered != null) {
        text = line.substring(ordered.end);
        blockAttrs = {'list': 'ordered'};
      }
    }

    for (final span in _parseInline(text)) {
      if (span.text.isEmpty) continue;
      final attrs = <String, dynamic>{};
      if (span.bold) attrs['bold'] = true;
      if (span.italic) attrs['italic'] = true;
      ops.add({
        'insert': span.text,
        if (attrs.isNotEmpty) 'attributes': attrs,
      });
    }

    ops.add({
      'insert': '\n',
      if (blockAttrs != null) 'attributes': blockAttrs,
    });
  }

  if (ops.isEmpty) ops.add({'insert': '\n'});
  return ops;
}

class _Span {
  const _Span(this.text, {this.bold = false, this.italic = false});
  final String text;
  final bool bold;
  final bool italic;
}

/// Splits a line into runs of plain / bold / italic text, handling `***`,
/// `**`, `*` and `_` markers (the subset the exporter emits).
List<_Span> _parseInline(String text) {
  final spans = <_Span>[];
  final re = RegExp(
    r'\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|_(.+?)_',
  );
  var index = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > index) spans.add(_Span(text.substring(index, m.start)));
    if (m.group(1) != null) {
      spans.add(_Span(m.group(1)!, bold: true, italic: true));
    } else if (m.group(2) != null) {
      spans.add(_Span(m.group(2)!, bold: true));
    } else {
      spans.add(_Span((m.group(3) ?? m.group(4))!, italic: true));
    }
    index = m.end;
  }
  if (index < text.length) spans.add(_Span(text.substring(index)));
  return spans;
}
