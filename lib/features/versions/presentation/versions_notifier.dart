import 'package:pluma/features/versions/data/versions_repository_impl.dart';
import 'package:pluma/features/versions/domain/document_version.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'versions_notifier.g.dart';

/// Newest-first stream of a document's saved versions.
@riverpod
Stream<List<DocumentVersion>> documentVersions(Ref ref, String documentId) {
  return ref.watch(versionsRepositoryProvider).watchForDocument(documentId);
}
