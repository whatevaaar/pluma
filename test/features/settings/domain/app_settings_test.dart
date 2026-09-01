import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';

void main() {
  group('AppSettings reminder time', () {
    test('parses "HH:mm" into hour and minute', () {
      const s = AppSettings(reminderTime: '07:35');
      expect(s.reminderHour, 7);
      expect(s.reminderMinute, 35);
    });

    test('defaults to 20:00', () {
      const s = AppSettings();
      expect(s.reminderHour, 20);
      expect(s.reminderMinute, 0);
    });

    test('falls back gracefully on malformed input', () {
      const s = AppSettings(reminderTime: 'garbage');
      expect(s.reminderHour, 20);
      expect(s.reminderMinute, 0);
    });

    test('round-trips through JSON', () {
      const s = AppSettings(reminderEnabled: true, reminderTime: '06:15');
      final restored = AppSettings.fromJson(s.toJson());
      expect(restored.reminderEnabled, isTrue);
      expect(restored.reminderTime, '06:15');
    });
  });
}
