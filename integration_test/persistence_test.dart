import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/pump_app.dart';
import 'helpers/test_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Persistence — write → restart → data intact', () {
    testWidgets('document content survives widget tree teardown and rebuild', (tester) async {
      final db = createTestDatabase();

      // Phase 1: Open app and write a document
      await tester.pumpApp(db);

      // TODO (Fase 1): tap new document button, enter text, wait for autosave
      // await tester.tap(find.byKey(const Key('new_document_fab')));
      // await tester.pumpAndSettle();
      // await tester.enterText(find.byType(QuillEditor), 'Hola persistencia');
      // await tester.pump(const Duration(seconds: 4)); // wait for autosave debounce

      // Phase 2: Simulate app "close" by tearing down the widget tree
      await tester.pumpWidget(const SizedBox.shrink());

      // Phase 3: Reopen with the same database instance (same in-memory store)
      await tester.pumpApp(db);

      // TODO (Fase 1): verify document appears in library list
      // expect(find.text('Hola persistencia'), findsOneWidget);

      await db.close();
    });
  });
}
