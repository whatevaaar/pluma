import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/reminders/data/notification_service.dart';
import 'package:pluma/features/reminders/presentation/reminder_controller.dart';
import 'package:pluma/features/settings/data/settings_repository_impl.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';

import '../../shared/fakes/fake_settings_repository.dart';

/// Records calls instead of touching the platform plugin.
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({this.granted = true});

  final bool granted;
  int scheduleCalls = 0;
  int cancelCalls = 0;
  int? lastHour;
  int? lastMinute;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async => granted;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    scheduleCalls++;
    lastHour = hour;
    lastMinute = minute;
  }

  @override
  Future<void> cancelReminder() async => cancelCalls++;
}

Future<(ProviderContainer, FakeSettingsRepository)> _container(
  _FakeNotificationService service,
) async {
  final repo = FakeSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWith((ref) async => repo),
      notificationServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(container.dispose);
  // Keep the auto-dispose settings provider alive while we await its value.
  container.listen(settingsProvider, (_, __) {});
  await container.read(settingsProvider.future); // ensure settings loaded
  return (container, repo);
}

void main() {
  test('enabling with permission schedules and persists', () async {
    final service = _FakeNotificationService();
    final (container, repo) = await _container(service);
    final controller = container.read(reminderControllerProvider.notifier);

    final ok = await controller.setEnabled(true);

    expect(ok, isTrue);
    expect(service.scheduleCalls, 1);
    expect(service.lastHour, 20); // default 20:00
    expect((await repo.getSettings()).reminderEnabled, isTrue);
  });

  test('enabling without permission does not persist or schedule', () async {
    final service = _FakeNotificationService(granted: false);
    final (container, repo) = await _container(service);
    final controller = container.read(reminderControllerProvider.notifier);

    final ok = await controller.setEnabled(true);

    expect(ok, isFalse);
    expect(service.scheduleCalls, 0);
    expect((await repo.getSettings()).reminderEnabled, isFalse);
  });

  test('disabling cancels the scheduled reminder', () async {
    final service = _FakeNotificationService();
    final (container, repo) = await _container(service);
    final controller = container.read(reminderControllerProvider.notifier);

    await controller.setEnabled(true);
    await controller.setEnabled(false);

    expect(service.cancelCalls, greaterThanOrEqualTo(1));
    expect((await repo.getSettings()).reminderEnabled, isFalse);
  });

  test('changing the time persists it', () async {
    final service = _FakeNotificationService();
    final (container, repo) = await _container(service);
    final controller = container.read(reminderControllerProvider.notifier);

    await controller.setTime(6, 5);

    expect((await repo.getSettings()).reminderTime, '06:05');
  });
}
