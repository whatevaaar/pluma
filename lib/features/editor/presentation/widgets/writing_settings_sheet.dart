import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';
import 'package:pluma/shared/widgets/writing_theme_picker.dart';

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

            // Tema de escritura — aplica a toda la app.
            Text('Tema', style: tt.labelMedium),
            const SizedBox(height: 8),
            WritingThemePicker(
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
