import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/extensions/datetime_ext.dart';

void main() {
  group('DateTimeExt.isSameDay', () {
    test('same day returns true', () {
      final a = DateTime(2026, 8, 12, 10);
      final b = DateTime(2026, 8, 12, 23, 59);
      expect(a.isSameDay(b), isTrue);
    });

    test('different day returns false', () {
      final a = DateTime(2026, 8, 12);
      final b = DateTime(2026, 8, 13);
      expect(a.isSameDay(b), isFalse);
    });

    test('different year returns false', () {
      final a = DateTime(2025, 8, 12);
      final b = DateTime(2026, 8, 12);
      expect(a.isSameDay(b), isFalse);
    });
  });

  group('DateTimeExt.toDateKey', () {
    test('formats as YYYY-MM-DD with zero-padding', () {
      final date = DateTime(2026, 1, 5);
      expect(date.toDateKey, '2026-01-05');
    });

    test('December 31 formats correctly', () {
      final date = DateTime(2026, 12, 31);
      expect(date.toDateKey, '2026-12-31');
    });
  });

  group('DateTimeExt.dateOnly', () {
    test('strips time component', () {
      final dt = DateTime(2026, 8, 12, 14, 35, 22);
      expect(dt.dateOnly, DateTime(2026, 8, 12));
    });
  });
}
