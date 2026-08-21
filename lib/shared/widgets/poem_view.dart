import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Read-only poem renderer.
///
/// Centers the text, preserves the author's manual line breaks, and auto-scales
/// the font so the widest line fits the available width AND the whole block
/// fits the height — it never soft-wraps a line the poet didn't break. This is
/// the shared engine behind the Poem Card export (and, later, a poetry
/// preview).
///
/// Because a line's rendered width scales linearly with font size, the fit is
/// solved exactly (no binary search): each line is measured once at a reference
/// size and [computeFontSize] closes the form.
class PoemView extends StatelessWidget {
  const PoemView({
    required this.body,
    required this.textColor,
    super.key,
    this.title,
    this.fontFamily,
    this.titleColor,
    this.padding = const EdgeInsets.all(28),
    this.minFontSize = 6,
    this.maxFontSize = 46,
    this.lineHeight = 1.4,
  });

  final String body;
  final String? title;
  final Color textColor;
  final Color? titleColor;
  final String? fontFamily;
  final EdgeInsets padding;
  final double minFontSize;
  final double maxFontSize;
  final double lineHeight;

  /// The title is rendered this much larger than the body, at this line height,
  /// with a gap of [_titleGapFactor] × bodyFontSize beneath it.
  static const double _titleScale = 1.3;
  static const double _titleLineHeight = 1.15;
  static const double _titleGapFactor = 1.2;

  /// Reference size at which line widths are measured before scaling.
  static const double _refSize = 100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth - padding.horizontal;
        final maxH = constraints.maxHeight - padding.vertical;
        final lines = body.isEmpty ? const [''] : body.split('\n');
        final hasTitle = title != null && title!.trim().isNotEmpty;

        final lineRefWidths = [
          for (final line in lines)
            if (line.isEmpty)
              0.0
            else
              _measure(line, _refSize, FontWeight.w400),
        ];
        final titleRefWidth = hasTitle
            ? _measure(title!, _refSize * _titleScale, FontWeight.w700)
            : 0.0;

        final fontSize = computeFontSize(
          maxWidth: maxW,
          maxHeight: maxH,
          lineRefWidths: lineRefWidths,
          titleRefWidth: titleRefWidth,
          hasTitle: hasTitle,
          minFontSize: minFontSize,
          maxFontSize: maxFontSize,
          lineHeight: lineHeight,
        );

        return Padding(
          padding: padding,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: fontSize * _titleScale,
                      height: _titleLineHeight,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? textColor,
                    ),
                  ),
                  SizedBox(height: fontSize * _titleGapFactor),
                ],
                Text(
                  body,
                  textAlign: TextAlign.center,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    height: lineHeight,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _measure(String text, double size, FontWeight weight) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  /// The largest font size (clamped to [[minFontSize], [maxFontSize]]) at which
  /// every body line and the title fit [maxWidth], and the whole block fits
  /// [maxHeight]. Pure — [lineRefWidths]/[titleRefWidth] are widths measured at
  /// [_refSize] (title measured at `_refSize * _titleScale`).
  static double computeFontSize({
    required double maxWidth,
    required double maxHeight,
    required List<double> lineRefWidths,
    required double titleRefWidth,
    required bool hasTitle,
    required double minFontSize,
    required double maxFontSize,
    required double lineHeight,
  }) {
    if (maxWidth <= 0 || maxHeight <= 0) return minFontSize;

    var size = maxFontSize;

    // Width: bodyLineWidth(size) = refWidth * size / _refSize <= maxWidth.
    final widestBodyRef = lineRefWidths.fold<double>(0, math.max);
    if (widestBodyRef > 0) {
      size = math.min(size, maxWidth * _refSize / widestBodyRef);
    }
    // The title ref width already includes the _titleScale factor.
    if (hasTitle && titleRefWidth > 0) {
      size = math.min(size, maxWidth * _refSize / titleRefWidth);
    }

    // Height is linear in size too.
    var heightFactor = lineRefWidths.length * lineHeight;
    if (hasTitle) {
      heightFactor += _titleScale * _titleLineHeight + _titleGapFactor;
    }
    if (heightFactor > 0) {
      size = math.min(size, maxHeight / heightFactor);
    }

    return size.clamp(minFontSize, maxFontSize);
  }
}
