import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide EditorState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/core/theme/app_text_styles.dart';
import 'package:pluma/features/editor/presentation/editor_notifier.dart';
import 'package:pluma/features/editor/presentation/widgets/word_count_bar.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _scrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  // Save when app goes to background — ensures no data loss if app is killed
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
    // In focus mode, tapping the editor area shows the toolbar briefly
    if (!_toolbarVisible) {
      setState(() => _toolbarVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorAsync = ref.watch(editorProvider(widget.documentId));
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();

    return editorAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error al cargar el documento: $e')),
      ),
      data: (state) {
        // Sync title controller without loop
        if (_titleController.text != state.document.title) {
          _titleController.text = state.document.title;
        }

        final focusMode = state.focusModeEnabled;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: focusMode
              ? null
              : _buildAppBar(context, state),
          body: GestureDetector(
            onTap: _onEditorTap,
            behavior: HitTestBehavior.translucent,
            child: Column(
              children: [
                // Title field
                if (!focusMode) _buildTitleField(context, state),

                // Editor — takes all available space
                Expanded(
                  child: _buildEditor(context, state, settings),
                ),

                // Bottom bars — hidden in focus mode
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

  PreferredSizeWidget _buildAppBar(BuildContext context, EditorState state) {
    final notifier = ref.read(
      editorProvider(widget.documentId).notifier,
    );

    return AppBar(
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

  Widget _buildTitleField(BuildContext context, EditorState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: _titleController,
        style: AppTextStyles.uiHeadline.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
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
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final editorFontSize = settings.editorFontSize;
    final lineHeight = settings.editorLineHeight;
    final columnWidth = settings.editorColumnWidth;

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
              fontSize: editorFontSize,
              height: lineHeight,
              color: colorScheme.onSurface,
            ),
            HorizontalSpacing.zero,
            VerticalSpacing.zero,
            VerticalSpacing.zero,
            null,
          ),
          h1: DefaultTextBlockStyle(
            AppTextStyles.editorBody.copyWith(
              fontSize: editorFontSize * 1.6,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: colorScheme.onSurface,
            ),
            HorizontalSpacing.zero,
            const VerticalSpacing(16, 8),
            VerticalSpacing.zero,
            null,
          ),
          h2: DefaultTextBlockStyle(
            AppTextStyles.editorBody.copyWith(
              fontSize: editorFontSize * 1.3,
              fontWeight: FontWeight.bold,
              height: 1.4,
              color: colorScheme.onSurface,
            ),
            HorizontalSpacing.zero,
            const VerticalSpacing(12, 6),
            VerticalSpacing.zero,
            null,
          ),
        ),
      ),
    );

    // Constrain editor width for readability — like iA Writer's column mode
    if (columnWidth != null) {
      editor = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: columnWidth),
          child: editor,
        ),
      );
    }

    // Typewriter mode: keep cursor centered vertically
    if (state.typewriterModeEnabled) {
      state.controller.addListener(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            Scrollable.maybeOf(context)?.position;
            // Scroll to keep cursor in the middle of the screen
          }
        });
      });
    }

    return editor;
  }

  void _showDocumentOptions(BuildContext context, EditorState state) {
    final notifier = ref.read(
      editorProvider(widget.documentId).notifier,
    );

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  state.typewriterModeEnabled
                      ? Icons.keyboard_outlined
                      : Icons.vertical_align_center,
                ),
                title: Text(
                  state.typewriterModeEnabled
                      ? 'Desactivar modo máquina de escribir'
                      : 'Modo máquina de escribir',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.toggleTypewriterMode();
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
