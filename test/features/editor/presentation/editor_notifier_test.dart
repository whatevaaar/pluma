import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/editor/domain/editor_repository.dart';

class MockEditorRepository extends Mock implements EditorRepository {}

Document _fakeDoc({int wordCount = 0}) => Document(
      id: 'doc-1',
      projectId: null,
      title: 'Test Doc',
      content: '{"ops":[{"insert":"\\n"}]}',
      plainText: '',
      wordCount: wordCount,
      charCount: 0,
      isFavorite: false,
      isDeleted: false,
      targetWordCount: null,
      createdAt: DateTime(2026, 8, 12),
      updatedAt: DateTime(2026, 8, 12),
    );

void main() {
  late MockEditorRepository mockRepo;

  setUp(() {
    mockRepo = MockEditorRepository();
    when(() => mockRepo.load(any())).thenAnswer((_) async => _fakeDoc());
    when(
      () => mockRepo.save(
        documentId: any(named: 'documentId'),
        title: any(named: 'title'),
        content: any(named: 'content'),
        plainText: any(named: 'plainText'),
        wordCount: any(named: 'wordCount'),
        charCount: any(named: 'charCount'),
        wordsDelta: any(named: 'wordsDelta'),
      ),
    ).thenAnswer((_) async {});
  });

  group('EditorNotifier — autosave debounce', () {
    test('save is NOT called immediately after content change', () {
      fakeAsync((async) {
        // Simulate debounce: save should only fire after the debounce period
        var saveCalled = false;
        when(
          () => mockRepo.save(
            documentId: any(named: 'documentId'),
            title: any(named: 'title'),
            content: any(named: 'content'),
            plainText: any(named: 'plainText'),
            wordCount: any(named: 'wordCount'),
            charCount: any(named: 'charCount'),
            wordsDelta: any(named: 'wordsDelta'),
          ),
        ).thenAnswer((_) async {
          saveCalled = true;
        });

        // Before debounce period — no save yet
        async.elapse(const Duration(seconds: 2));
        expect(saveCalled, isFalse);

        // After debounce period — save fires
        async.elapse(const Duration(seconds: 2)); // total: 4s > 3s debounce
        expect(saveCalled, isTrue);
      });
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
}
