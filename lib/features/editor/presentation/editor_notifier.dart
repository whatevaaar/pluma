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
import 'package:pluma/features/versions/data/versions_repository_impl.dart';
import 'package:pluma/features/versions/domain/document_version.dart';
import 'package:pluma/features/versions/domain/versions_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editor_notifier.freezed.dart';
part 'editor_notifier.g.dart';

/// True if the document has any center-aligned line — the persisted signal for
/// "poetry mode". Read from the Delta so it survives reloads.
bool isDocumentCentered(quill.QuillController controller) {
  for (final op in controller.document.toDelta().toList()) {
    if (op.attributes?['align'] == 'center') return true;
  }
  return false;
}

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
  late VersionsRepository _versionsRepo;
  Timer? _autosaveTimer;
  int _lastSavedWordCount = 0;

  // --- Version snapshot tracking ---
  // Content (Delta JSON) as loaded — used to skip snapshots when nothing
  // changed during the session.
  String? _loadedContent;
  // Latest persisted content/plain/word count, captured in _saveNow. The
  // session-end snapshot in onDispose reads these (state may be AsyncLoading
  // during disposal).
  String? _lastSavedContent;
  String? _lastSavedPlain;
  int _lastSavedWordCountForSnap = 0;
  // Content of the most recent snapshot and when it was taken — drives the
  // throttle so autosaves don't spam the history.
  String? _lastSnapshotContent;
  DateTime? _lastSnapshotAt;
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
    _versionsRepo = ref.read(versionsRepositoryProvider);
    _sessionStart = DateTime.now();
    _sessionWordsDelta = 0;
    // Throttle window starts at session start so the first auto snapshot can't
    // fire until versionSnapshotInterval into the session.
    _lastSnapshotAt = _sessionStart;

    ref.onDispose(() {
      _autosaveTimer?.cancel();
      // Do NOT gate on state.value: in Riverpod 3.x, state may be AsyncLoading
      // during disposal (e.g. when a dependency is rebuilt just before the
      // widget pops). state.value would be null and recordSession() would be
      // silently skipped, causing statistics to always show zero.
      // documentId is available via the generated _$EditorNotifier getter and
      // does not require a non-null AsyncData state.
      final wordsDelta = _sessionWordsDelta;
      final elapsed = DateTime.now().difference(_sessionStart).inSeconds;
      unawaited(
        _statsRepo
            .recordSession(
              documentId: documentId,
              wordsDelta: wordsDelta,
              durationSeconds: elapsed,
              startedAt: _sessionStart,
            )
            .catchError((Object e, StackTrace st) {
              debugPrint('[EditorNotifier] recordSession failed: $e\n$st');
            }),
      );

      // Session-end snapshot: capture the final saved state so the whole
      // session is recoverable. Skipped when nothing changed or an auto
      // snapshot already captured this exact content.
      final finalContent = _lastSavedContent;
      if (finalContent != null &&
          finalContent != _loadedContent &&
          finalContent != _lastSnapshotContent) {
        unawaited(
          _versionsRepo
              .snapshot(
                documentId: documentId,
                content: finalContent,
                plainText: _lastSavedPlain ?? '',
                wordCount: _lastSavedWordCountForSnap,
                reason: 'session',
              )
              .catchError((Object e, StackTrace st) {
                debugPrint('[EditorNotifier] session snapshot failed: $e\n$st');
              }),
        );
      }
    });

    final doc = await _repo.load(documentId);
    if (doc == null) throw StateError('Document $documentId not found');

    _lastSavedWordCount = doc.wordCount;
    _loadedContent = doc.content;

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

    _lastSavedContent = deltaJson;
    _lastSavedPlain = plain;
    _lastSavedWordCountForSnap = wc;

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

    await _maybeAutoSnapshot(deltaJson, plain, wc);
  }

  // --- Version snapshots ---

  /// Snapshots the current content if it changed since the last snapshot and
  /// the throttle window has elapsed. No-op otherwise.
  Future<void> _maybeAutoSnapshot(String content, String plain, int wc) async {
    if (content == _loadedContent) return; // unchanged since load
    if (content == _lastSnapshotContent) return; // already captured
    final last = _lastSnapshotAt;
    if (last != null &&
        DateTime.now().difference(last) <
            AppConstants.versionSnapshotInterval) {
      return; // throttled
    }
    await _snapshot(content: content, plain: plain, wc: wc, reason: 'auto');
  }

  Future<void> _snapshot({
    required String content,
    required String plain,
    required int wc,
    required String reason,
  }) async {
    try {
      await _versionsRepo.snapshot(
        documentId: documentId,
        content: content,
        plainText: plain,
        wordCount: wc,
        reason: reason,
      );
      _lastSnapshotContent = content;
      _lastSnapshotAt = DateTime.now();
    } on Object catch (e, st) {
      debugPrint('[EditorNotifier] snapshot failed: $e\n$st');
    }
  }

  /// Manually saves a version of the current content (from the editor menu).
  Future<void> saveVersionNow() async {
    final current = state.value;
    if (current == null) return;
    final content =
        jsonEncode({'ops': current.controller.document.toDelta().toJson()});
    final plain = current.controller.document.toPlainText();
    await _snapshot(
      content: content,
      plain: plain,
      wc: plain.wordCount,
      reason: 'manual',
    );
  }

  /// Restores [version]'s content into the live document. Snapshots the
  /// current content first (reason 'pre-restore') so the restore is itself
  /// reversible, then swaps in a controller built from the version and
  /// persists.
  Future<void> restoreVersion(DocumentVersion version) async {
    final current = state.value;
    if (current == null) return;

    final currentContent =
        jsonEncode({'ops': current.controller.document.toDelta().toJson()});
    final currentPlain = current.controller.document.toPlainText();
    await _snapshot(
      content: currentContent,
      plain: currentPlain,
      wc: currentPlain.wordCount,
      reason: 'pre-restore',
    );

    current.controller.removeListener(_onContentChanged);
    final controller = _buildController(version.content)
      ..addListener(_onContentChanged);
    final plain = controller.document.toPlainText();
    _lastSavedWordCount = plain.wordCount;
    state = AsyncData(
      current.copyWith(
        controller: controller,
        document: current.document.copyWith(
          content: version.content,
          plainText: plain,
          wordCount: plain.wordCount,
          charCount: plain.charCount,
        ),
      ),
    );

    await _saveNow();
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

  /// Toggles poetry mode: center-aligns the whole document (or clears the
  /// alignment when turning off). The mode isn't stored in [EditorState] — it
  /// lives in the document's own alignment and is read back via
  /// [isDocumentCentered]. The formatting edit fires the content listener,
  /// which rebuilds the UI and persists via autosave.
  void togglePoetryMode() {
    final controller = state.requireValue.controller;
    final next = !isDocumentCentered(controller);
    controller.formatText(
      0,
      controller.document.length,
      next
          ? quill.Attribute.centerAlignment
          : quill.Attribute.clone(quill.Attribute.leftAlignment, null),
    );
  }

  void toggleTypewriterMode() {
    final current = state.requireValue;
    final next = !current.typewriterModeEnabled;
    state = AsyncData(current.copyWith(typewriterModeEnabled: next));
    unawaited(ref.read(settingsProvider.notifier).setTypewriterMode(next));
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
