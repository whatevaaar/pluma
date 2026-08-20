import 'package:flutter/material.dart';

import 'package:pluma/core/theme/app_text_styles.dart';

/// Compact bottom bar showing word count, character count, and autosave status.
class WordCountBar extends StatelessWidget {
  const WordCountBar({
    required this.wordCount,
    required this.charCount,
    required this.isSaving,
    super.key,
    this.targetWordCount,
    this.backgroundColor,
    this.foregroundColor,
  });

  final int wordCount;
  final int charCount;
  final bool isSaving;
  final int? targetWordCount;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surface;
    final fgColor = foregroundColor ?? colorScheme.onSurfaceVariant;
    final labelStyle = AppTextStyles.uiCaption.copyWith(
      color: fgColor.withAlpha(180),
    );

    final hasTarget = targetWordCount != null && targetWordCount! > 0;
    final progress = hasTarget
        ? (wordCount / targetWordCount!).clamp(0.0, 1.0)
        : null;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: fgColor.withAlpha(40), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            _formatCount(wordCount, 'palabra', 'palabras'),
            style: labelStyle,
          ),
          const SizedBox(width: 12),
          Text('$charCount car.', style: labelStyle),
          if (hasTarget) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: fgColor.withAlpha(40),
                color: progress! >= 1.0
                    ? colorScheme.primary
                    : colorScheme.primary.withAlpha(160),
                borderRadius: BorderRadius.circular(2),
                minHeight: 3,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '/ ${_formatCount(targetWordCount!, 'palabra', 'palabras')}',
              style: labelStyle,
            ),
          ],
          const Spacer(),
          if (isSaving)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: fgColor.withAlpha(180),
                  ),
                ),
                const SizedBox(width: 6),
                Text('Guardando…', style: labelStyle),
              ],
            ),
        ],
      ),
    );
  }

  String _formatCount(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }
}
