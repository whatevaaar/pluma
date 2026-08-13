import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/string_ext.dart';
import '../../documents/domain/document.dart';
import '../data/editor_repository_impl.dart';
import '../domain/editor_repository.dart';

part 'editor_notifier.freezed.dart';
part 'editor_notifier.g.dart';

@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    required Document document,
    required QuillController controller,
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
  Timer? _autosaveTimer;
  // Track word count at last save to compute deltas
  int _lastSavedWordCount = 0;

  @override
  Future<EditorState> build(String documentId) async {
    _repo = ref.watch(editorRepositoryProvider);

    ref.onDispose(() {
      _autosaveTimer?.cancel();
      // Final save happens on dispose to catch any unsaved changes
      _saveNow();
    });

    final doc = await _repo.load(documentId);
    if (doc == null) throw StateError('Document $documentId not found');

    _lastSavedWordCount = doc.wordCount;

    final controller = _buildController(doc.content);
    controller.addListener(_onContentChanged);

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

  QuillController _buildController(String deltaJson) {
    try {
      final doc = Document.fromJson(
        (deltaJson.isNotEmpty ? deltaJson : '{"ops":[{"insert":"\\n"}]}'),
      );
      return QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      return QuillController.basic();
    }
  }

  void _onContentChanged() {
    _scheduleAutosave();
    // Update word count reactively on every change (lightweight — uses cached plainText)
    final plain = state.valueOrNull?.controller.document.toPlainText() ?? '';
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
    final current = state.valueOrNull;
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
      wordsDelta: delta,
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
}
