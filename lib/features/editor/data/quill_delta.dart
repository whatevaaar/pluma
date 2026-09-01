import 'dart:convert';

import 'package:flutter/widgets.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Encodes a Quill document to the Delta JSON string Pluma persists
/// (`{"ops":[...]}`). Centralised so the exact shape — which a past bug
/// regressed — lives in one place.
String encodeQuillDelta(quill.Document document) =>
    jsonEncode({'ops': document.toDelta().toJson()});

/// Builds a [quill.QuillController] from persisted Delta JSON, falling back to
/// an empty document when [deltaJson] is blank or malformed.
quill.QuillController buildQuillController(
  String deltaJson, {
  bool readOnly = false,
}) {
  try {
    final raw =
        deltaJson.isNotEmpty ? deltaJson : r'{"ops":[{"insert":"\n"}]}';
    final ops =
        (jsonDecode(raw) as Map<String, dynamic>)['ops'] as List<dynamic>;
    return quill.QuillController(
      document: quill.Document.fromJson(ops),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: readOnly,
    );
  } on Object catch (_) {
    return quill.QuillController.basic()..readOnly = readOnly;
  }
}
