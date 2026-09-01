import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/core/theme/writing_theme_colors.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';

class WritingSettingsSheet extends ConsumerStatefulWidget {
  const WritingSettingsSheet({super.key});

  @override
  ConsumerState<WritingSettingsSheet> createState() =>
      _WritingSettingsSheetState();
}

class _WritingSettingsSheetState extends ConsumerState<WritingSettingsSheet> {
  // Local state for sliders — written to settings only on drag end.
  late double _fontSize;
  late double _lineHeight;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).value ?? const AppSettings();
    _fontSize = settings.editorFontSize;
    _lineHeight = settings.editorLineHeight;
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tema de escritura
            Text('Tema', style: tt.labelMedium),
            const SizedBox(height: 8),
            _ThemeChips(
              selected: settings.writingTheme,
              onSelected: notifier.setWritingTheme,
            ),
            const SizedBox(height: 20),

            // Fuente
            Text('Fuente', style: tt.labelMedium),
            const SizedBox(height: 8),
            _FontChips(
              selected: settings.editorFont,
              onSelected: notifier.setEditorFont,
            ),
            const SizedBox(height: 20),

            // Tamaño de fuente
            Row(
              children: [
                Text('Tamaño', style: tt.labelMedium),
                const Spacer(),
                Text(
                  '${_fontSize.round()}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              onChanged: (v) => setState(() => _fontSize = v),
              onChangeEnd: notifier.setEditorFontSize,
            ),
            const SizedBox(height: 12),

            // Interlineado
            Row(
              children: [
                Text('Interlineado', style: tt.labelMedium),
                const Spacer(),
                Text(
                  _lineHeight.toStringAsFixed(1),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            Slider(
              value: _lineHeight,
              min: 1.2,
              max: 2.4,
              divisions: 12,
              onChanged: (v) => setState(() => _lineHeight = v),
              onChangeEnd: notifier.setEditorLineHeight,
            ),
            const SizedBox(height: 12),

            // Modo máquina de escribir
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Modo máquina de escribir', style: tt.bodyMedium),
              subtitle: Text(
                'Mantiene el cursor centrado en pantalla',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              value: settings.typewriterMode,
              onChanged: notifier.setTypewriterMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChips extends StatelessWidget {
  const _ThemeChips({required this.selected, required this.onSelected});

  final WritingTheme selected;
  final ValueChanged<WritingTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 92,
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

class _FontChips extends StatelessWidget {
  const _FontChips({required this.selected, required this.onSelected});

  final EditorFont selected;
  final ValueChanged<EditorFont> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: EditorFont.values.map((font) {
        return ChoiceChip(
          label: Text(font.displayName),
          selected: font == selected,
          onSelected: (_) => onSelected(font),
        );
      }).toList(),
    );
  }
}
