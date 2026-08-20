import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pluma/features/documents/domain/document.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class DocumentExporter {
  DocumentExporter._();

  /// Returns a filesystem-safe version of [displayTitle], falling back to
  /// 'documento' if the result is blank.
  static String _safeTitle(Document doc) {
    final safe = doc.displayTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim();
    return safe.isEmpty ? 'documento' : safe;
  }

  // ---------------------------------------------------------------------------
  // TXT
  // ---------------------------------------------------------------------------

  /// Shares the document's plain text as a `.txt` file.
  static Future<void> exportAsTxt(Document doc) async {
    final title = _safeTitle(doc);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$title.txt');
    await file.writeAsString(doc.plainText);
    await Share.shareXFiles([XFile(file.path)]);
  }

  // ---------------------------------------------------------------------------
  // Markdown
  // ---------------------------------------------------------------------------

  /// Converts [controller]'s Delta to Markdown and shares as a `.md` file.
  static Future<void> exportAsMarkdown(
    Document doc,
    QuillController controller,
  ) async {
    final markdown = _deltaToMarkdown(doc.content);
    final title = _safeTitle(doc);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$title.md');
    await file.writeAsString(markdown);
    await Share.shareXFiles([XFile(file.path)]);
  }

  /// Converts Quill Delta JSON (stored in [deltaJson] as {"ops":[...]}) to a
  /// Markdown string.
  static String _deltaToMarkdown(String deltaJson) {
    final List<dynamic> ops;
    try {
      final decoded = jsonDecode(deltaJson) as Map<String, dynamic>;
      ops = decoded['ops'] as List<dynamic>;
    } catch (_) {
      return '';
    }

    final buffer = StringBuffer();
    // Buffer accumulates inline text for the current line until a newline op
    // is encountered.
    final lineBuffer = StringBuffer();
    int orderedCounter = 0;

    for (final rawOp in ops) {
      if (rawOp is! Map<String, dynamic>) continue;
      final insert = rawOp['insert'];
      final attrs = rawOp['attributes'] as Map<String, dynamic>?;

      if (insert is String) {
        // Split on newline: everything before is inline content; each '\n'
        // terminates a line and triggers block-level attribute handling.
        final parts = insert.split('\n');

        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];

          if (part.isNotEmpty) {
            // Apply inline formatting.
            final isBold = attrs?['bold'] == true;
            final isItalic = attrs?['italic'] == true;

            String text = part;
            if (isBold && isItalic) {
              text = '***$text***';
            } else if (isBold) {
              text = '**$text**';
            } else if (isItalic) {
              text = '*$text*';
            }
            lineBuffer.write(text);
          }

          // Every element after the first in [parts] represents a '\n' in the
          // original string (because split('\n') on "a\nb" → ["a","b"]).
          if (i < parts.length - 1) {
            // Flush line buffer with block-level prefix.
            final lineText = lineBuffer.toString();
            lineBuffer.clear();

            // The '\n' op carries block attributes on the LAST op of the
            // paragraph; here that op IS the newline split.
            final header = attrs?['header'];
            final list = attrs?['list'];

            if (header == 1) {
              buffer.writeln('# $lineText');
              orderedCounter = 0;
            } else if (header == 2) {
              buffer.writeln('## $lineText');
              orderedCounter = 0;
            } else if (list == 'bullet') {
              buffer.writeln('- $lineText');
              orderedCounter = 0;
            } else if (list == 'ordered') {
              orderedCounter++;
              buffer.writeln('$orderedCounter. $lineText');
            } else {
              buffer.writeln(lineText);
              orderedCounter = 0;
            }
          }
        }
      }
    }

    // Flush any remaining content in the line buffer (no trailing newline op).
    final remaining = lineBuffer.toString();
    if (remaining.isNotEmpty) {
      buffer.write(remaining);
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  /// Generates a PDF from the document and shares it via the printing package.
  static Future<void> exportAsPdf(Document doc) async {
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          pw.Text(
            doc.displayTitle,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            doc.plainText,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
            textAlign: pw.TextAlign.left,
          ),
        ],
      ),
    );

    final title = _safeTitle(doc);
    await Printing.sharePdf(
      bytes: await pdfDoc.save(),
      filename: '$title.pdf',
    );
  }
}
