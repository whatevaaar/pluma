import 'package:flutter/material.dart';

import 'package:pluma/core/extensions/datetime_ext.dart';
import 'package:pluma/core/extensions/number_ext.dart';
import 'package:pluma/core/theme/app_colors.dart';
import 'package:pluma/core/theme/app_text_styles.dart';
import 'package:pluma/features/documents/domain/document.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    required this.document,
    required this.onTap,
    super.key,
    this.onFavoriteTap,
    this.onLongPress,
    this.onMenuTap,
  });

  final Document document;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuTap;

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
                          ? (isDark
                              ? AppColors.heatmap3Dark
                              : AppColors.heatmap3)
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
                  document.wordCount.formatAsWordCount(),
                  style: AppTextStyles.wordCountBadge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite indicator: rendered only when starred, so
                    // favorites are visible at a glance in the list. Tapping
                    // it removes the document from favorites.
                    if (document.isFavorite && onFavoriteTap != null)
                      _IconTap(
                        icon: Icons.bookmark,
                        color: colorScheme.primary,
                        onTap: onFavoriteTap!,
                        tooltip: 'Quitar de favoritos',
                      ),
                    if (onMenuTap != null)
                      _IconTap(
                        icon: Icons.more_vert,
                        color: colorScheme.onSurfaceVariant,
                        onTap: onMenuTap!,
                        tooltip: 'Más opciones',
                      )
                    else if (onFavoriteTap != null && !document.isFavorite)
                      _IconTap(
                        icon: Icons.bookmark_border,
                        color: colorScheme.onSurfaceVariant,
                        onTap: onFavoriteTap!,
                        tooltip: 'Añadir a favoritos',
                      ),
                  ],
                ),
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
    final short = preview.length > 60
        ? '${preview.substring(0, 60)}…'
        : preview;
    return '$date · $short';
  }

  String _formatDate(DateTime dt) {
    if (dt.isToday) return 'Hoy';
    if (dt.isYesterday) return 'Ayer';
    return dt.toSpanishMediumDate();
  }
}

/// A compact 18px trailing icon with a padded, rippling tap area (~30px) so
/// the tap target is comfortable without inflating the row height.
class _IconTap extends StatelessWidget {
  const _IconTap({
    required this.icon,
    required this.color,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }
}
