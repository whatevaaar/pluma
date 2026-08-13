import 'package:flutter/material.dart';

import '../../../../core/extensions/datetime_ext.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/document.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onTap,
    this.onFavoriteTap,
    this.onLongPress,
  });

  final Document document;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.displayTitle,
                    style: AppTextStyles.documentTitle.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _buildSubtitle(),
                    style: AppTextStyles.documentSubtitle.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Word count progress bar if there's a target
                  if (document.hasTarget) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: document.targetCompletion,
                      backgroundColor: colorScheme.outlineVariant,
                      color: document.targetCompletion >= 1.0
                          ? (isDark ? AppColors.heatmap3Dark : AppColors.heatmap3)
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                      minHeight: 2,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatWordCount(document.wordCount),
                  style: AppTextStyles.wordCountBadge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (onFavoriteTap != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onFavoriteTap,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      document.isFavorite
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 18,
                      color: document.isFavorite
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final preview = document.plainText.trim();
    final date = _formatDate(document.updatedAt);
    if (preview.isEmpty) return date;
    final short = preview.length > 60 ? '${preview.substring(0, 60)}…' : preview;
    return '$date · $short';
  }

  String _formatDate(DateTime dt) {
    if (dt.isToday) return 'Hoy';
    if (dt.isYesterday) return 'Ayer';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatWordCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k pal.';
    }
    return '$count pal.';
  }
}
