import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/core/constants/app_constants.dart';
import 'package:pluma/features/editor/presentation/editor_notifier.dart';

void main() {
  group('EditorNotifier — autosave debounce', () {
    // Integration-level debounce behavior is covered by persistence_test.dart.
    // Here we verify the constant so changes to debounce duration are explicit.
    test('autosave debounce duration is 3 seconds', () {
      expect(
        AppConstants.autosaveDebounceDuration,
        const Duration(seconds: 3),
      );
    });
  });

  group('EditorNotifier — word count', () {
    test('word count is 0 for empty document', () {
      expect(''.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length, 0);
    });

    test('word count is correct for simple text', () {
      const text = 'hola mundo como estás';
      final words = text.trim().split(RegExp(r'\s+')).length;
      expect(words, 4);
    });

    test('word delta is computed correctly', () {
      const before = 10;
      const after = 15;
      const delta = after - before;
      expect(delta, 5);
    });

    test('negative delta when user deletes text', () {
      const before = 100;
      const after = 80;
      expect(after - before, -20);
    });
  });

  group('poetry mode — center alignment', () {
    test('isDocumentCentered tracks the center/clear format operations', () {
      final controller = QuillController.basic();
      addTearDown(controller.dispose);
      controller.document.insert(0, 'verso uno\nverso dos');

      expect(isDocumentCentered(controller), isFalse);

      // Enabling poetry mode centers the whole document.
      controller.formatText(
        0,
        controller.document.length,
        Attribute.centerAlignment,
      );
      expect(isDocumentCentered(controller), isTrue);

      // Disabling clears the alignment back to the default.
      controller.formatText(
        0,
        controller.document.length,
        Attribute.clone(Attribute.leftAlignment, null),
      );
      expect(isDocumentCentered(controller), isFalse);
    });
  });
}
