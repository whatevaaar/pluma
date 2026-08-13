import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/trash/domain/trash_repository.dart';
import 'package:uuid/uuid.dart';

class FakeTrashRepository implements TrashRepository {
  final docs = <String, Document>{};

  Document seedDeleted({String? id, String title = 'Test'}) {
    final now = DateTime.now();
    final doc = Document(
      id: id ?? const Uuid().v4(),
      title: title,
      content: r'{"ops":[{"insert":"\n"}]}',
      plainText: '',
      wordCount: 0,
      charCount: 0,
      isFavorite: false,
      isDeleted: true,
      deletedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    docs[doc.id] = doc;
    return doc;
  }

  @override
  Stream<List<Document>> watchDeleted() {
    return Stream.value(
      docs.values.where((d) => d.isDeleted).toList()
        ..sort(
          (a, b) => (b.deletedAt ?? DateTime(0))
              .compareTo(a.deletedAt ?? DateTime(0)),
        ),
    );
  }

  @override
  Future<void> moveToTrash(String documentId) async {
    final d = docs[documentId];
    if (d != null) {
      docs[documentId] = d.copyWith(isDeleted: true, deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> restore(String documentId) async {
    final d = docs[documentId];
    if (d != null) {
      docs[documentId] = d.copyWith(isDeleted: false, deletedAt: null);
    }
  }

  @override
  Future<void> deletePermanently(String documentId) async {
    docs.remove(documentId);
  }

  @override
  Future<void> emptyTrash() async {
    docs.removeWhere((_, d) => d.isDeleted);
  }
}
