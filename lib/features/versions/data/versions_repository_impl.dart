import 'package:drift/drift.dart';
import 'package:pluma/core/constants/app_constants.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/versions/data/version_row_ext.dart';
import 'package:pluma/features/versions/data/versions_dao.dart';
import 'package:pluma/features/versions/domain/document_version.dart';
import 'package:pluma/features/versions/domain/versions_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'versions_repository_impl.g.dart';

class VersionsRepositoryImpl implements VersionsRepository {
  VersionsRepositoryImpl(this._dao);

  final VersionsDao _dao;

  @override
  Stream<List<DocumentVersion>> watchForDocument(String documentId) {
    return _dao.watchForDocument(documentId).map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        );
  }

  @override
  Future<DocumentVersion?> findById(String id) async {
    final row = await _dao.findById(id);
    return row?.toDomain();
  }

  @override
  Future<void> snapshot({
    required String documentId,
    required String content,
    required String plainText,
    required int wordCount,
    String? reason,
    int keep = AppConstants.maxVersionsPerDocument,
  }) async {
    await _dao.insert(
      DocumentVersionsCompanion(
        id: Value(const Uuid().v4()),
        documentId: Value(documentId),
        content: Value(content),
        plainText: Value(plainText),
        wordCount: Value(wordCount),
        createdAt: Value(DateTime.now()),
        reason: Value(reason),
      ),
    );
    await _dao.pruneOldest(documentId, keep: keep);
  }

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);
}

@riverpod
VersionsRepository versionsRepository(Ref ref) =>
    VersionsRepositoryImpl(ref.watch(versionsDaoProvider));
