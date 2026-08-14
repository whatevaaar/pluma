import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' hide EditorState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/core/theme/app_text_styles.dart';
import 'package:pluma/core/theme/writing_theme_colors.dart';
import 'package:pluma/features/editor/presentation/editor_notifier.dart';
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
        SystemChrome.setEnabledSystemUIMode(
          nextFocus ? SystemUiMode.immersive : SystemUiMode.edgeToEdge,
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

        return Scaffold(
          backgroundColor: writingColors.background,
          appBar: focusMode
              ? null
              : _buildAppBar(context, state, writingColors),
          body: GestureDetector(
            onTap: _onEditorTap,
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                if (!focusMode)
                  _buildTitleField(context, state, writingColors),

                Expanded(
                  child: _buildEditor(context, state, settings, writingColors),
                ),

                if (!focusMode) ...[
                  WritingToolbar(controller: state.controller),
                  WordCountBar(
                    wordCount: state.document.wordCount,
                    charCount: state.document.charCount,
                    isSaving: state.isSaving,
                    targetWordCount: state.document.targetWordCount,
                  ),
                ],
              ],
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
          await notifier.saveNow();
          if (context.mounted) Navigator.of(context).pop();
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
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: state.focusModeEnabled ? 60 : 16,
        ),
        placeholder: 'Empieza a escribir…',
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
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Establecer objetivo de palabras'),
                onTap: () {
                  Navigator.pop(ctx);
                  // TODO(pluma): Fase 5 — implement word target dialog
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
