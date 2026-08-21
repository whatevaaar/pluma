import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/trash/data/trash_repository_impl.dart';
import 'package:pluma/features/trash/presentation/trash_notifier.dart';

import '../../../shared/fakes/fake_trash_repository.dart';

ProviderContainer _makeContainer(FakeTrashRepository fake) {
  return ProviderContainer(
    overrides: [trashRepositoryProvider.overrideWithValue(fake)],
  );
}

void main() {
  group('TrashNotifier', () {
    test('initializes with empty list when trash is empty', () async {
      final fake = FakeTrashRepository();
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final state = await container.read(trashProvider.future);

      expect(state, isEmpty);
    });

    test('initializes with all deleted documents', () async {
      final fake = FakeTrashRepository()
        ..seedDeleted(title: 'Borrador')
        ..seedDeleted(title: 'Notas');

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final state = await container.read(trashProvider.future);

      expect(state.length, 2);
      expect(state.every((d) => d.isDeleted), isTrue);
    });

    test('restore marks document as not deleted', () async {
      final fake = FakeTrashRepository();
      final doc = fake.seedDeleted(title: 'Restaurar');

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(trashProvider.future);
      await container.read(trashProvider.notifier).restore(doc.id);

      expect(fake.docs[doc.id]?.isDeleted, isFalse);
      expect(fake.docs[doc.id]?.deletedAt, isNull);
    });

    test('deletePermanently removes document from storage', () async {
      final fake = FakeTrashRepository();
      final doc = fake.seedDeleted(title: 'Definitivo');

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(trashProvider.future);
      await container.read(trashProvider.notifier).deletePermanently(doc.id);

      expect(fake.docs.containsKey(doc.id), isFalse);
    });

    test('emptyTrash removes all deleted documents', () async {
      final fake = FakeTrashRepository()
        ..seedDeleted(title: 'Doc 1')
        ..seedDeleted(title: 'Doc 2')
        ..seedDeleted(title: 'Doc 3');

      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(trashProvider.future);
      await container.read(trashProvider.notifier).emptyTrash();

      final deleted = fake.docs.values.where((d) => d.isDeleted);
      expect(deleted, isEmpty);
    });
  });
}
