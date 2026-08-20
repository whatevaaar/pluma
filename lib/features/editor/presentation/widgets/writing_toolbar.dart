import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Formatting toolbar for the editor.
///
/// Deliberately minimal — only the formatting options writers actually use.
/// Hidden in focus mode; revealed on tap.
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
      height: 44,
      // Clip.hardEdge prevents the toolbar's internal Container (42px) from
      // ever overflowing into WordCountBar below.
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: fgColor.withAlpha(40), width: 0.5),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: controller,
        config: QuillSimpleToolbarConfig(
          // multiRowsDisplay: false switches from a Wrap (which defaults to
          // true and overflows the 44px Container across two rows, painting
          // over WordCountBar) to a horizontally-scrollable single row.
          // config.color is only read in the single-row Container branch,
          // so both properties must be set together.
          multiRowsDisplay: false,
          color: bgColor,
          showFontSize: false,
          showBackgroundColorButton: false,
          showColorButton: false,
          showClearFormat: false,
          showIndent: false,
          showLink: false,
          showSearchButton: false,
          showSubscript: false,
          showSuperscript: false,
          showInlineCode: false,
          showCodeBlock: false,
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
        ),
      ),
    );
  }
}
