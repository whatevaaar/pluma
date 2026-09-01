import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Formatting toolbar for the editor.
///
/// Built from flutter_quill's individual button widgets (not
/// [QuillSimpleToolbar]) so the layout is fully controlled: uniform,
/// tightly-sized buttons, a crisp active pill, and the buttons grouped
/// (history · inline styles · lists) with hairline dividers, centered when
/// they fit and horizontally scrollable when they don't.
///
/// Requires `FlutterQuillLocalizations.delegate` to be registered in the app
/// (see [MaterialApp.localizationsDelegates]); without it every toolbar button
/// throws during build and renders as a blank gray ErrorWidget in release.
class WritingToolbar extends StatelessWidget {
  const WritingToolbar({
    required this.controller,
    this.backgroundColor,
    this.foregroundColor,
    this.onHideKeyboard,
    this.keyboardVisible = false,
    super.key,
  });

  final QuillController controller;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Called when the trailing "hide keyboard" button is tapped. When null the
  /// button is never shown.
  final VoidCallback? onHideKeyboard;

  /// Whether the soft keyboard is currently visible. The hide-keyboard button
  /// animates in only while the keyboard is up.
  final bool keyboardVisible;

  static const double _buttonSize = 38;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surface;
    final fgColor = foregroundColor ?? colorScheme.onSurfaceVariant;

    ButtonStyle styleFrom({required bool selected}) => IconButton.styleFrom(
          fixedSize: const Size(_buttonSize, _buttonSize),
          minimumSize: const Size(_buttonSize, _buttonSize),
          padding: EdgeInsets.zero,
          // Shrink-wrap the tap target: the default 48px material target is
          // what makes a compact toolbar feel loose and spread out.
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          backgroundColor: selected ? fgColor.withAlpha(30) : null,
          foregroundColor: selected ? fgColor : fgColor.withAlpha(150),
        );

    final baseOptions = QuillToolbarBaseButtonOptions<dynamic, dynamic>(
      iconSize: _iconSize,
      iconButtonFactor: 1,
      iconTheme: QuillIconTheme(
        iconButtonSelectedData:
            IconButtonData(style: styleFrom(selected: true)),
        iconButtonUnselectedData:
            IconButtonData(style: styleFrom(selected: false)),
      ),
    );

    Widget toggle(Attribute<dynamic> attribute) =>
        QuillToolbarToggleStyleButton(
          attribute: attribute,
          controller: controller,
          baseOptions: baseOptions,
        );

    final groups = <List<Widget>>[
      [
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
      ],
      [
        toggle(Attribute.bold),
        toggle(Attribute.italic),
        toggle(Attribute.underline),
        toggle(Attribute.strikeThrough),
      ],
      [
        toggle(Attribute.ul),
        toggle(Attribute.ol),
        QuillToolbarToggleCheckListButton(
          controller: controller,
          baseOptions: baseOptions,
        ),
      ],
    ];

    // Interleave groups with hairline dividers.
    final children = <Widget>[];
    for (var g = 0; g < groups.length; g++) {
      if (g > 0) children.add(_Divider(color: fgColor.withAlpha(38)));
      children.addAll(groups[g]);
    }

    // Trailing, pinned-right control to dismiss the keyboard. Cross-fades and
    // shrinks in/out so the toolbar reflows smoothly with the keyboard.
    final showHideKeyboard = onHideKeyboard != null && keyboardVisible;
    final hideKeyboard = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: showHideKeyboard ? 1 : 0,
        child: showHideKeyboard
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Divider(color: fgColor.withAlpha(38)),
                  IconButton(
                    icon: const Icon(Icons.keyboard_hide_outlined),
                    iconSize: _iconSize,
                    style: styleFrom(selected: false),
                    tooltip: 'Ocultar teclado',
                    onPressed: onHideKeyboard,
                  ),
                  const SizedBox(width: 4),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: fgColor.withAlpha(38), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  // Fill width so the row centers when it fits; else scrolls.
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
          hideKeyboard,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: color,
    );
  }
}
