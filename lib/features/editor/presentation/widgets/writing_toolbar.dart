import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Formatting toolbar for the editor.
///
/// A [QuillSimpleToolbar] trimmed to the buttons we actually want and themed
/// to the writing surface. Requires `FlutterQuillLocalizations.delegate` to be
/// registered in the app (see [MaterialApp.localizationsDelegates]); without
/// it every toolbar button throws during build and the toolbar renders as a
/// blank gray ErrorWidget in release mode.
class WritingToolbar extends StatelessWidget {
  const WritingToolbar({
    required this.controller,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final QuillController controller;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surface;
    final fgColor = foregroundColor ?? colorScheme.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: fgColor.withAlpha(40), width: 0.5),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: controller,
        config: QuillSimpleToolbarConfig(
          color: bgColor,
          // Single horizontal scrolling row instead of the default wrapping
          // multi-row grid.
          multiRowsDisplay: false,
          showDividers: false,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconSize: 20,
              iconTheme: QuillIconTheme(
                iconButtonSelectedData: IconButtonData(
                  style: IconButton.styleFrom(
                    backgroundColor: fgColor.withAlpha(30),
                    foregroundColor: fgColor,
                  ),
                ),
                iconButtonUnselectedData: IconButtonData(
                  style: IconButton.styleFrom(
                    foregroundColor: fgColor.withAlpha(153),
                  ),
                ),
              ),
            ),
          ),
          // Curated button set: undo/redo, bold/italic/underline/strike, and
          // the three list buttons are kept (all default to true). Everything
          // below is explicitly hidden.
          showFontFamily: false,
          showFontSize: false,
          showInlineCode: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showHeaderStyle: false,
          showCodeBlock: false,
          showQuote: false,
          showIndent: false,
          showLink: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
        ),
      ),
    );
  }
}
