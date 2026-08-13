import '../../documents/domain/document.dart';

abstract interface class TrashRepository {
  Stream<List<Document>> watchDeleted();

  Future<void> moveToTrash(String documentId);

  Future<void> restore(String documentId);

  Future<void> deletePermanently(String documentId);

  Future<void> emptyTrash();
}
