import 'dart:async' show Timer, unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pluma/core/constants/app_constants.dart';
import 'package:pluma/core/extensions/string_ext.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/editor/data/editor_repository_impl.dart';
import 'package:pluma/features/editor/domain/editor_repository.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';
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
  // Accumulated on every _saveNow() BEFORE any await, so concurrent calls
  // (autosave timer + saveNow() on back) each add their own delta atomically
  // on the single Dart thread. onDispose reads this field, not state.value,
  // to avoid the race where the second saveNow() overwrites state with 0.
  int _sessionWordsDelta = 0;
  DateTime _sessionStart = DateTime.now();

  @override
  Future<EditorState> build(String documentId) async {
    _repo = ref.watch(editorRepositoryProvider);
    // ref.read (not watch): settingsProvider changes must not rebuild the
    // editor mid-session, which would reset _sessionWordsDelta and
    // _lastSavedWordCount, losing the session's accumulated delta.
    _statsRepo = ref.read(statisticsRepositoryProvider);
    _sessionStart = DateTime.now();
    _sessionWordsDelta = 0;

    ref.onDispose(() {
      _autosaveTimer?.cancel();
      final current = state.value;
      if (current != null) {
        // Read _sessionWordsDelta (field), not state.value.sessionWordsDelta.
        // The race: autosave fires → _saveNow() A captures current(delta=0),
        // user presses back → _saveNow() B captures current(delta=0) too,
        // B completes first and writes state(delta=0), A writes state(delta=N)
        // but onDispose may already be reading between the two. The field
        // is incremented synchronously before any await in _saveNow(), so
        // both calls accumulate into it without collision on the single thread.
        final wordsDelta = _sessionWordsDelta;
        final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
        unawaited(
          _statsRepo
              .recordSession(
                documentId: current.document.id,
                wordsDelta: wordsDelta,
                durationSeconds: elapsed,
                startedAt: _sessionStart,
              )
              .catchError((Object e, StackTrace st) {
                debugPrint('[EditorNotifier] recordSession failed: $e\n$st');
              }),
        );
      }
    });

    final doc = await _repo.load(documentId);
    if (doc == null) throw StateError('Document $documentId not found');

    _lastSavedWordCount = doc.wordCount;

    final controller = _buildController(doc.content)
      ..addListener(_onContentChanged);

    // Read settings once at initialization — not watched to avoid recreating
    // the QuillController every time settings change.
    final initialTypewriterMode =
        ref.read(settingsProvider).value?.typewriterMode ?? false;

    return EditorState(
      document: doc,
      controller: controller,
      isSaving: false,
      focusModeEnabled: false,
      typewriterModeEnabled: initialTypewriterMode,
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
    _autosaveTimer = Timer(
      AppConstants.autosaveDebounceDuration,
      () => unawaited(_saveNow()),
    );
  }

  Future<void> _saveNow() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSaving: true));

    final plain = current.controller.document.toPlainText();
    final wc = plain.wordCount;
    final cc = plain.charCount;
    final deltaJson =
        jsonEncode({'ops': current.controller.document.toDelta().toJson()});
    final delta = wc - _lastSavedWordCount;
    _lastSavedWordCount = wc;
    // Accumulate to field before the first await so concurrent _saveNow()
    // calls each add their own slice. If the save fails, roll back.
    _sessionWordsDelta += delta;

    try {
      await _repo.save(
        documentId: current.document.id,
        title: current.document.title,
        content: deltaJson,
        plainText: plain,
        wordCount: wc,
        charCount: cc,
        targetWordCount: current.document.targetWordCount,
      );
    } on Object catch (e, st) {
      _sessionWordsDelta -= delta;
      debugPrint('[EditorNotifier] Save failed: $e\n$st');
      state = AsyncData(current.copyWith(isSaving: false));
      rethrow;
    }

    state = AsyncData(
      current.copyWith(
        isSaving: false,
        document: current.document.copyWith(
          plainText: plain,
          wordCount: wc,
          charCount: cc,
          updatedAt: DateTime.now(),
        ),
        sessionWordsDelta: _sessionWordsDelta,
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
    final next = !current.typewriterModeEnabled;
    state = AsyncData(current.copyWith(typewriterModeEnabled: next));
    ref.read(settingsProvider.notifier).setTypewriterMode(next);
  }

  Future<void> updateTargetWordCount(int? target) async {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        document: current.document.copyWith(targetWordCount: target),
      ),
    );
    await _saveNow();
  }

  /// Force-save immediately (called before navigating away).
  Future<void> saveNow() => _saveNow();
}
