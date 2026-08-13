import 'dart:async' show Timer, unawaited;
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pluma/core/constants/app_constants.dart';
import 'package:pluma/core/extensions/string_ext.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/editor/data/editor_repository_impl.dart';
import 'package:pluma/features/editor/domain/editor_repository.dart';
import 'package:pluma/features/statistics/data/statistics_repository_impl.dart';
import 'package:pluma/features/statistics/domain/statistics_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_notifier.freezed.dart';
part 'editor_notifier.g.dart';

@freezed
abstract class EditorState with _$EditorState {
  const factory EditorState({
    required Document document,
    required quill.QuillController controller,
    required bool isSaving,
    required bool focusModeEnabled,
    required bool typewriterModeEnabled,
    // Words written in this session (used for stats delta)
    required int sessionWordsDelta,
    // Word count at the moment the session started
    required int sessionStartWordCount,
  }) = _EditorState;
}

@riverpod
class EditorNotifier extends _$EditorNotifier {
  late EditorRepository _repo;
  late StatisticsRepository _statsRepo;
  Timer? _autosaveTimer;
  int _lastSavedWordCount = 0;
  DateTime _sessionStart = DateTime.now();

  @override
  Future<EditorState> build(String documentId) async {
    _repo = ref.watch(editorRepositoryProvider);
    _statsRepo = ref.watch(statisticsRepositoryProvider);
    _sessionStart = DateTime.now();

    ref.onDispose(() {
      _autosaveTimer?.cancel();
      unawaited(_saveAndRecord());
    });

    final doc = await _repo.load(documentId);
    if (doc == null) throw StateError('Document $documentId not found');

    _lastSavedWordCount = doc.wordCount;

    final controller = _buildController(doc.content)
      ..addListener(_onContentChanged);

    return EditorState(
      document: doc,
      controller: controller,
      isSaving: false,
      focusModeEnabled: false,
      typewriterModeEnabled: false,
      sessionWordsDelta: 0,
      sessionStartWordCount: doc.wordCount,
    );
  }

  quill.QuillController _buildController(String deltaJson) {
    try {
      final raw = deltaJson.isNotEmpty
          ? deltaJson
          : r'{"ops":[{"insert":"\n"}]}';
      final ops =
          (jsonDecode(raw) as Map<String, dynamic>)['ops'] as List<dynamic>;
      final doc = quill.Document.fromJson(ops);
      return quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } on Object catch (_) {
      return quill.QuillController.basic();
    }
  }

  void _onContentChanged() {
    _scheduleAutosave();
    // Update word count reactively on every change
    // (lightweight — uses cached plainText)
    final plain = state.value?.controller.document.toPlainText() ?? '';
    final count = plain.wordCount;
    state = AsyncData(
      state.requireValue.copyWith(
        document: state.requireValue.document.copyWith(wordCount: count),
      ),
    );
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(AppConstants.autosaveDebounceDuration, _saveNow);
  }

  Future<void> _saveNow() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));

    final plain = current.controller.document.toPlainText();
    final wc = plain.wordCount;
    final cc = plain.charCount;
    final deltaJson = current.controller.document.toDelta().toJson().toString();
    final delta = wc - _lastSavedWordCount;
    _lastSavedWordCount = wc;

    await _repo.save(
      documentId: current.document.id,
      title: current.document.title,
      content: deltaJson,
      plainText: plain,
      wordCount: wc,
      charCount: cc,
    );

    state = AsyncData(
      current.copyWith(
        isSaving: false,
        document: current.document.copyWith(
          plainText: plain,
          wordCount: wc,
          charCount: cc,
          updatedAt: DateTime.now(),
        ),
        sessionWordsDelta: current.sessionWordsDelta + delta,
      ),
    );
  }

  Future<void> updateTitle(String title) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        document: current.document.copyWith(title: title),
      ),
    );
    _scheduleAutosave();
  }

  void toggleFocusMode() {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(focusModeEnabled: !current.focusModeEnabled),
    );
  }

  void toggleTypewriterMode() {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(typewriterModeEnabled: !current.typewriterModeEnabled),
    );
  }

  /// Force-save immediately (called before navigating away).
  Future<void> saveNow() => _saveNow();

  Future<void> _saveAndRecord() async {
    await _saveNow();
    final current = state.value;
    final delta = current?.sessionWordsDelta ?? 0;
    final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
    await _statsRepo.recordSession(
      documentId: current?.document.id ?? '',
      wordsDelta: delta,
      durationSeconds: elapsed,
      startedAt: _sessionStart,
    );
  }
}
