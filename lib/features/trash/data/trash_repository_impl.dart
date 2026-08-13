import 'package:pluma/features/documents/data/document_row_ext.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/trash/data/trash_dao.dart';
import 'package:pluma/features/trash/domain/trash_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_repository_impl.g.dart';

class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._dao);

  final TrashDao _dao;

  @override
  Stream<List<Document>> watchDeleted() {
    return _dao.watchDeleted().map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<void> moveToTrash(String documentId) {
    return _dao.softDelete(documentId);
  }

  @override
  Future<void> restore(String documentId) {
    return _dao.restore(documentId);
  }

  @override
  Future<void> deletePermanently(String documentId) {
    return _dao.deletePermanently(documentId);
  }

  @override
  Future<void> emptyTrash() {
    return _dao.emptyTrash();
  }

  @override
  Future<void> purgeExpiredTrash() {
    return _dao.purgeExpiredTrash();
  }
}

@riverpod
TrashRepository trashRepository(Ref ref) =>
    TrashRepositoryImpl(ref.watch(trashDaoProvider));
