import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Document, EditorState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pluma/core/theme/app_text_styles.dart';
import 'package:pluma/core/theme/writing_theme_colors.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/editor/data/document_exporter.dart';
import 'package:pluma/features/editor/presentation/editor_notifier.dart';
import 'package:pluma/features/editor/presentation/poem_card_screen.dart';
import 'package:pluma/features/editor/presentation/widgets/word_count_bar.dart';
import 'package:pluma/features/editor/presentation/widgets/writing_settings_sheet.dart';
import 'package:pluma/features/editor/presentation/widgets/writing_toolbar.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({required this.documentId, super.key});

  final String documentId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  final _titleController = TextEditingController();
  final _scrollController = ScrollController();
  final _editorFocusNode = FocusNode();
  bool _toolbarVisible = true;

  // Tracks which controller has the typewriter listener attached.
  QuillController? _typewriterController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typewriterController?.removeListener(_onTypewriterCursorChange);
    _titleController.dispose();
    _scrollController.dispose();
    _editorFocusNode.dispose();
    // Restore system UI in case focus mode was active when we left.
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    );
    super.dispose();
  }

  // Save when app goes to background — ensures no data loss if app is killed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(
        ref.read(editorProvider(widget.documentId).notifier).saveNow(),
      );
    }
  }

  void _onEditorTap() {
    if (!_toolbarVisible) setState(() => _toolbarVisible = true);
  }

  // --- Typewriter mode ---

  /// Attaches the typewriter scroll listener to [controller] exactly once.
  /// Removes the listener from any previously tracked controller first.
  void _attachTypewriterListener(QuillController controller) {
    if (_typewriterController == controller) return;
    _typewriterController?.removeListener(_onTypewriterCursorChange);
    _typewriterController = controller;
    controller.addListener(_onTypewriterCursorChange);
  }

  void _onTypewriterCursorChange() {
    final editorValue = ref.read(editorProvider(widget.documentId)).value;
    if (editorValue?.typewriterModeEnabled != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollForTypewriter());
  }

  void _scrollForTypewriter() {
    if (!mounted || !_scrollController.hasClients) return;
    final editorValue = ref.read(editorProvider(widget.documentId)).value;
    final controller = editorValue?.controller;
    if (controller == null) return;

    final plain = controller.document.toPlainText();
    final cursor = controller.selection.baseOffset.clamp(0, plain.length);
    final lineCount = '\n'.allMatches(plain.substring(0, cursor)).length;

    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    final lineH = settings.editorFontSize * settings.editorLineHeight;
    final screenH = MediaQuery.of(context).size.height;
    final target = (lineCount * lineH) - (screenH * 0.42);

    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  // --- Writing settings sheet ---

  void _showWritingSettings(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const WritingSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorAsync = ref.watch(editorProvider(widget.documentId));
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final brightness = Theme.of(context).brightness;
    final writingColors =
        WritingThemeColors.resolve(settings.writingTheme, brightness);

    // Immersive focus mode: toggle system UI when focus mode changes.
    ref.listen<AsyncValue<EditorState>>(
      editorProvider(widget.documentId),
      (prev, next) {
        final prevFocus = prev?.value?.focusModeEnabled ?? false;
        final nextFocus = next.value?.focusModeEnabled ?? false;
        if (prevFocus == nextFocus) return;
        unawaited(
          SystemChrome.setEnabledSystemUIMode(
            nextFocus ? SystemUiMode.immersive : SystemUiMode.edgeToEdge,
          ),
        );
      },
    );

    return editorAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error al cargar el documento: $e')),
      ),
      data: (state) {
        // Sync title controller without triggering a rebuild loop.
        if (_titleController.text != state.document.title) {
          _titleController.text = state.document.title;
        }

        // Attach typewriter listener once per controller instance.
        _attachTypewriterListener(state.controller);

        final focusMode = state.focusModeEnabled;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final notifier =
                ref.read(editorProvider(widget.documentId).notifier);
            try {
              await notifier.saveNow();
            } finally {
              if (context.mounted) context.pop();
            }
          },
          child: Scaffold(
            backgroundColor: writingColors.background,
            // resizeToAvoidBottomInset: false prevents the Scaffold from
            // shrinking the body during the keyboard slide-in animation.
            // When true (the default), the body resize and the native iOS
            // keyboard animation run on different timers, leaving a strip of
            // the iOS system background (gray) visible between the Flutter
            // content and the keyboard for the duration of the transition.
            // The keyboard inset is instead handled explicitly via the
            // SizedBox at the bottom of the Column, driven directly by
            // MediaQuery.viewInsetsOf and tracking the keyboard frame by frame.
            resizeToAvoidBottomInset: false,
            appBar: focusMode
                ? null
                : _buildAppBar(context, state, writingColors),
            body: GestureDetector(
              onTap: _onEditorTap,
              behavior: HitTestBehavior.translucent,
              // Cross-fade the writing surface when the theme changes so
              // switching palettes feels like a gentle dissolve, not a snap.
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                color: writingColors.background,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Title collapses smoothly when entering focus mode.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: focusMode
                              ? const SizedBox(width: double.infinity)
                              : _buildTitleField(context, state, writingColors),
                        ),

                        Expanded(
                          child: _buildEditor(
                            context,
                            state,
                            settings,
                            writingColors,
                          ),
                        ),

                        // Toolbar + word count slide/collapse together when
                        // focus mode toggles.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: focusMode
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    WritingToolbar(
                                      controller: state.controller,
                                      backgroundColor:
                                          writingColors.appBarBackground,
                                      foregroundColor:
                                          writingColors.onBackground,
                                      keyboardVisible:
                                          MediaQuery.viewInsetsOf(context)
                                                  .bottom >
                                              0,
                                      onHideKeyboard: _editorFocusNode.unfocus,
                                    ),
                                    WordCountBar(
                                      wordCount: state.document.wordCount,
                                      charCount: state.document.charCount,
                                      isSaving: state.isSaving,
                                      targetWordCount:
                                          state.document.targetWordCount,
                                      backgroundColor:
                                          writingColors.appBarBackground,
                                      foregroundColor:
                                          writingColors.onBackground,
                                    ),
                                  ],
                                ),
                        ),

                        // Keyboard inset: expands to exactly the keyboard
                        // height so the toolbar stack is always above the
                        // keyboard. With resizeToAvoidBottomInset: false the
                        // body's MediaQuery preserves the raw viewInsets, so
                        // this SizedBox tracks the keyboard animation frame by
                        // frame with no gray gap.
                        SizedBox(
                          height: MediaQuery.viewInsetsOf(context).bottom,
                        ),
                      ],
                    ),

                    // In focus mode the app bar and toolbar are hidden, so
                    // these floating controls are the only way to exit focus
                    // mode and dismiss the keyboard.
                    _buildFocusModeControls(context, writingColors, focusMode),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EditorState state,
    WritingThemeColors writingColors,
  ) {
    final notifier = ref.read(editorProvider(widget.documentId).notifier);

    return AppBar(
      backgroundColor: writingColors.appBarBackground,
      leading: BackButton(
        onPressed: () async {
          try {
            await notifier.saveNow();
          } finally {
            if (context.mounted) context.pop();
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.center_focus_strong_outlined),
          tooltip: 'Modo focus',
          onPressed: notifier.toggleFocusMode,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Más opciones',
          onPressed: () => _showDocumentOptions(context, state),
        ),
      ],
    );
  }

  /// Floating controls shown only in focus mode: exit focus mode and hide
  /// the keyboard. Positioned top-right, low-opacity so they stay unobtrusive
  /// while remaining tappable.
  Widget _buildFocusModeControls(
    BuildContext context,
    WritingThemeColors writingColors,
    bool focusMode,
  ) {
    final notifier = ref.read(editorProvider(widget.documentId).notifier);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final tint = writingColors.onBackground;

    Widget button({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Material(
        color: writingColors.appBarBackground.withAlpha(160),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: Icon(icon, size: 20),
          color: tint.withAlpha(180),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      );
    }

    // Kept mounted and faded so it dissolves in/out with focus mode rather than
    // popping. IgnorePointer disables taps while hidden.
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IgnorePointer(
            ignoring: !focusMode,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              offset: focusMode ? Offset.zero : const Offset(0, -0.4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: focusMode ? 1 : 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      child: keyboardVisible
                          ? Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: button(
                                icon: Icons.keyboard_hide_outlined,
                                tooltip: 'Ocultar teclado',
                                onPressed: _editorFocusNode.unfocus,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    button(
                      icon: Icons.close_fullscreen_outlined,
                      tooltip: 'Salir de pantalla completa',
                      onPressed: notifier.toggleFocusMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(
    BuildContext context,
    EditorState state,
    WritingThemeColors writingColors,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: _titleController,
        style: AppTextStyles.uiHeadline.copyWith(
          color: writingColors.onBackground,
        ),
        decoration: const InputDecoration(
          hintText: 'Sin título',
          border: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        textCapitalization: TextCapitalization.sentences,
        onChanged: (value) => ref
            .read(editorProvider(widget.documentId).notifier)
            .updateTitle(value),
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    EditorState state,
    AppSettings settings,
    WritingThemeColors writingColors,
  ) {
    final fontSize = settings.editorFontSize;
    final lineHeight = settings.editorLineHeight;
    final columnWidth = settings.editorColumnWidth;
    final fontFamily = settings.editorFont.fontFamily;
    final textColor = writingColors.onBackground;

    Widget editor = QuillEditor(
      controller: state.controller,
      scrollController: _scrollController,
      focusNode: _editorFocusNode,
      config: QuillEditorConfig(
        expands: true,
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: state.focusModeEnabled ? 60 : 16,
        ),
        placeholder: 'Empieza a escribir…',
        // Per-theme caret + selection colors. flutter_quill reads its cursor
        // color from this TextSelectionThemeData, so each writing palette gets
        // a high-contrast insertion point that stays clearly visible.
        textSelectionThemeData: TextSelectionThemeData(
          cursorColor: writingColors.cursor,
          selectionColor: writingColors.selection,
          selectionHandleColor: writingColors.cursor,
        ),
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            AppTextStyles.editorBody.copyWith(
              fontFamily: fontFamily,
              fontSize: fontSize,
              height: lineHeight,
              color: textColor,
            ),
            HorizontalSpacing.zero,
            VerticalSpacing.zero,
            VerticalSpacing.zero,
            null,
          ),
          h1: DefaultTextBlockStyle(
            AppTextStyles.editorBody.copyWith(
              fontFamily: fontFamily,
              fontSize: fontSize * 1.6,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: textColor,
            ),
            HorizontalSpacing.zero,
            const VerticalSpacing(16, 8),
            VerticalSpacing.zero,
            null,
          ),
          h2: DefaultTextBlockStyle(
            AppTextStyles.editorBody.copyWith(
              fontFamily: fontFamily,
              fontSize: fontSize * 1.3,
              fontWeight: FontWeight.bold,
              height: 1.4,
              color: textColor,
            ),
            HorizontalSpacing.zero,
            const VerticalSpacing(12, 6),
            VerticalSpacing.zero,
            null,
          ),
        ),
      ),
    );

    // Constrain editor width for readability — like iA Writer's column mode.
    if (columnWidth != null) {
      editor = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: columnWidth),
          child: editor,
        ),
      );
    }

    return editor;
  }

  void _showWordTargetDialog(BuildContext context, EditorState state) {
    final currentTarget = state.document.targetWordCount;
    final controller = TextEditingController(
      text: currentTarget != null && currentTarget > 0
          ? currentTarget.toString()
          : '',
    );
    final notifier = ref.read(editorProvider(widget.documentId).notifier);

    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Objetivo de palabras'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Número de palabras',
              hintText: 'p. ej. 1000',
            ),
            autofocus: true,
          ),
          actions: [
            if (currentTarget != null && currentTarget > 0)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(notifier.updateTargetWordCount(null));
                },
                child: const Text('Quitar objetivo'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                final text = controller.text.trim();
                final parsed = text.isEmpty ? null : int.tryParse(text);
                unawaited(notifier.updateTargetWordCount(parsed));
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Flushes pending edits, then hands the freshly-saved document to [export].
  /// TXT/PDF export from [Document.plainText], which only reflects the last
  /// save — without this they'd miss the latest keystrokes.
  Future<void> _exportFresh(
    Future<void> Function(Document document) export,
  ) async {
    final notifier = ref.read(editorProvider(widget.documentId).notifier);
    await notifier.saveNow();
    final fresh = ref.read(editorProvider(widget.documentId)).value;
    if (fresh == null) return;
    await export(fresh.document);
  }

  Future<void> _openPoemCard(BuildContext context, EditorState state) async {
    // Flush pending edits first: state.document only carries the last *saved*
    // plainText, while the live text lives in the controller. Without this the
    // poem card renders a stale snapshot (missing the most recent keystrokes).
    final notifier = ref.read(editorProvider(widget.documentId).notifier);
    await notifier.saveNow();
    final fresh = ref.read(editorProvider(widget.documentId)).value ?? state;

    final fontFamily =
        ref.read(settingsProvider).value?.editorFont.fontFamily;
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PoemCardScreen(
          document: fresh.document,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  void _showDocumentOptions(BuildContext context, EditorState state) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Apariencia'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showWritingSettings(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_align_center),
                title: const Text('Modo poesía'),
                subtitle: const Text('Centra el texto del poema'),
                trailing: isDocumentCentered(state.controller)
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(editorProvider(widget.documentId).notifier)
                      .togglePoetryMode();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Establecer objetivo de palabras'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showWordTargetDialog(context, state);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Compartir como imagen'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_openPoemCard(context, state));
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Exportar como TXT'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_exportFresh(DocumentExporter.exportAsTxt));
                },
              ),
              ListTile(
                leading: const Icon(Icons.code_outlined),
                title: const Text('Exportar como Markdown'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    DocumentExporter.exportAsMarkdown(
                      state.document,
                      state.controller,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Exportar como PDF'),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_exportFresh(DocumentExporter.exportAsPdf));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
