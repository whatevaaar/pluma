import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/features/reminders/presentation/reminder_controller.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';

/// "Recordatorios" settings block: a daily writing reminder with a time picker.
class ReminderSettingsSection extends ConsumerWidget {
  const ReminderSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final controller = ref.read(reminderControllerProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: Text('Recordatorio diario', style: tt.bodyMedium),
            subtitle: Text(
              'Un aviso para escribir cada día',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            value: settings.reminderEnabled,
            onChanged: (value) async {
              final ok = await controller.setEnabled(value);
              if (!context.mounted) return;
              if (value && !ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Activa las notificaciones para Pluma en los ajustes '
                      'del sistema.',
                    ),
                  ),
                );
              }
            },
          ),

          // Time row appears only when the reminder is on.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: settings.reminderEnabled
                ? Column(
                    children: [
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.schedule_outlined),
                        title: Text('Hora', style: tt.bodyMedium),
                        trailing: Text(
                          settings.reminderTime,
                          style: tt.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: settings.reminderHour,
                              minute: settings.reminderMinute,
                            ),
                          );
                          if (picked == null) return;
                          await controller.setTime(picked.hour, picked.minute);
                        },
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
