import 'package:flutter/material.dart';
import 'package:pluma/core/theme/writing_theme_colors.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';

/// Horizontal row of live theme previews. Selecting one changes the app-wide
/// theme. Shared between the main Settings screen and the editor's appearance
/// sheet.
class WritingThemePicker extends StatelessWidget {
  const WritingThemePicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final WritingTheme selected;
  final ValueChanged<WritingTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        itemCount: WritingTheme.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final theme = WritingTheme.values[i];
          return _ThemeSwatch(
            theme: theme,
            // Named palettes ignore the brightness arg; default follows it.
            colors: WritingThemeColors.resolve(theme, brightness),
            selected: theme == selected,
            onTap: () => onSelected(theme),
          );
        },
      ),
    );
  }
}

/// A tappable live preview of a writing theme: its surface, text tone and
/// caret color, with an animated selection ring.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final WritingTheme theme;
  final WritingThemeColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        scale: selected ? 1.04 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 84,
              height: 56,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      color: colors.onBackground,
                      fontFamily: 'Merriweather',
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 3),
                  // Caret sample in the theme's cursor color.
                  Container(width: 2, height: 22, color: colors.cursor),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 84,
              child: Text(
                theme.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
