import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/app_version_provider.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';
import 'package:pluma/shared/widgets/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Apariencia ──────────────────────────────────────────────────
          const SectionHeader(
            label: 'Apariencia',
            padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema de la app', style: tt.bodyMedium),
                  const SizedBox(height: 12),
                  Center(
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Claro'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Oscuro'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selected) =>
                          notifier.setThemeMode(selected.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Escritura ────────────────────────────────────────────────────
          const SectionHeader(
            label: 'Escritura',
            padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
          ),
          Card(
            child: Column(
              children: [
                // Daily word target stepper
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Meta diaria de palabras',
                                style: tt.bodyMedium,),
                            const SizedBox(height: 2),
                            Text(
                              'Objetivo de escritura por día',
                              style: tt.bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _WordTargetStepper(
                        value: settings.dailyWordTarget,
                        onChanged: notifier.setDailyWordTarget,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Typewriter mode
                SwitchListTile.adaptive(
                  title: Text('Modo máquina de escribir', style: tt.bodyMedium),
                  subtitle: Text(
                    'Mantiene el cursor centrado',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  value: settings.typewriterMode,
                  onChanged: notifier.setTypewriterMode,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Typographic quotes
                SwitchListTile.adaptive(
                  title: Text('Comillas tipográficas', style: tt.bodyMedium),
                  subtitle: Text(
                    'Convierte " " en “” automáticamente',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  value: settings.typographicQuotes,
                  onChanged: notifier.setTypographicQuotes,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                // Autocorrect
                SwitchListTile.adaptive(
                  title: Text('Autocorrección', style: tt.bodyMedium),
                  subtitle: Text(
                    'Corrige errores tipográficos automáticamente',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  value: settings.autocorrect,
                  onChanged: notifier.setAutocorrect,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Acerca de ────────────────────────────────────────────────────
          const SectionHeader(
            label: 'Acerca de',
            padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        // .value is null only for the brief async load; fall
                        // back to the bare name rather than a stale hardcoded
                        // version.
                        'Pluma ${ref.watch(appVersionProvider).value ?? ''}'
                            .trimRight(),
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin rastreo. Sin servidor. 100% tuyo.',
                    style:
                        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

// ── Word target stepper ──────────────────────────────────────────────────────

class _WordTargetStepper extends StatelessWidget {
  const _WordTargetStepper({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  static const int _min = 100;
  static const int _max = 5000;
  static const int _step = 50;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          enabled: value > _min,
          colorScheme: cs,
          onPressed: () {
            final next = (value - _step).clamp(_min, _max);
            onChanged(next);
          },
        ),
        SizedBox(
          width: 64,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          enabled: value < _max,
          colorScheme: cs,
          onPressed: () {
            final next = (value + _step).clamp(_min, _max);
            onChanged(next);
          },
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.colorScheme,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final ColorScheme colorScheme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      icon: Icon(icon, size: 18),
      onPressed: enabled ? onPressed : null,
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
