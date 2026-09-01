import 'package:pluma/features/reminders/data/notification_service.dart';
import 'package:pluma/features/settings/data/settings_repository_impl.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_controller.g.dart';

@riverpod
NotificationService notificationService(Ref ref) => NotificationService();

/// Orchestrates the daily reminder: persists the preference and keeps the
/// scheduled OS notification in sync with it.
@riverpod
class ReminderController extends _$ReminderController {
  @override
  void build() {}

  NotificationService get _service => ref.read(notificationServiceProvider);

  AppSettings get _settings =>
      ref.read(settingsProvider).value ?? const AppSettings();

  /// Enables or disables the daily reminder. When enabling, requests OS
  /// permission first and returns `false` (leaving it disabled) if it was
  /// denied.
  Future<bool> setEnabled(bool enabled) async {
    final settingsNotifier = ref.read(settingsProvider.notifier);

    if (!enabled) {
      await settingsNotifier.setReminderEnabled(false);
      await _service.cancelReminder();
      return true;
    }

    await _service.init();
    final granted = await _service.requestPermissions();
    if (!granted) return false;

    await settingsNotifier.setReminderEnabled(true);
    final s = _settings;
    await _service.scheduleDailyReminder(
      hour: s.reminderHour,
      minute: s.reminderMinute,
    );
    return true;
  }

  /// Updates the reminder time and reschedules if reminders are on.
  Future<void> setTime(int hour, int minute) async {
    final time = '${_two(hour)}:${_two(minute)}';
    await ref.read(settingsProvider.notifier).setReminderTime(time);
    if (_settings.reminderEnabled) {
      await _service.scheduleDailyReminder(hour: hour, minute: minute);
    }
  }

  /// Reconciles the OS schedule with the saved preference on app start (e.g.
  /// after a reboot or app update clears pending notifications).
  Future<void> syncOnStartup() async {
    try {
      final repo = await ref.read(settingsRepositoryProvider.future);
      final s = await repo.getSettings();
      if (!s.reminderEnabled) return;
      await _service.scheduleDailyReminder(
        hour: s.reminderHour,
        minute: s.reminderMinute,
      );
    } on Object catch (_) {
      // Scheduling can fail on unsupported platforms (e.g. desktop) or when
      // permission was revoked in OS settings — never block app startup.
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
