import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Formatting toolbar for the editor.
///
/// Built from individual flutter_quill button widgets in a plain Container
/// so the background color is 100% controlled — no QuillSimpleToolbar
/// internals (MenuAnchor, DropdownButton, Theme fallbacks) that could
/// render gray regardless of the color config passed to them.
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

    final baseOptions = QuillToolbarBaseButtonOptions<dynamic, dynamic>(
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
    );

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: fgColor.withAlpha(40), width: 0.5),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            QuillToolbarHistoryButton(
              isUndo: true,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarHistoryButton(
              isUndo: false,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleStyleButton(
              attribute: Attribute.bold,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleStyleButton(
              attribute: Attribute.italic,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleStyleButton(
              attribute: Attribute.underline,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleStyleButton(
              attribute: Attribute.strikeThrough,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleStyleButton(
              attribute: Attribute.ul,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleStyleButton(
              attribute: Attribute.ol,
              controller: controller,
              baseOptions: baseOptions,
            ),
            QuillToolbarToggleCheckListButton(
              controller: controller,
              baseOptions: baseOptions,
            ),
          ],
        ),
      ),
    );
  }
}
