import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/empty_state.dart';
import 'library_notifier.dart';
import 'widgets/document_tile.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryNotifierProvider);
    final notifier = ref.read(libraryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: notifier.search,
              )
            : const Text('Mis escritos'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  notifier.search('');
                }
              });
            },
          ),
        ],
      ),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final docs = state.searchQuery.isNotEmpty
              ? state.searchResults
              : state.documents;

          if (docs.isEmpty && !state.isSearching) {
            return EmptyState(
              title: 'Tu historia empieza aquí',
              subtitle: 'Crea tu primer documento y empieza a escribir.',
              actionLabel: 'Crear documento',
              action: () => _createAndOpenDocument(context, notifier),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              return DocumentTile(
                document: doc,
                onTap: () => context.pushNamed(
                  'editor',
                  pathParameters: {'documentId': doc.id},
                ),
                onFavoriteTap: () => notifier.toggleFavorite(doc.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('new_document_fab'),
        onPressed: () => _createAndOpenDocument(context, notifier),
        tooltip: 'Nuevo documento',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  Future<void> _createAndOpenDocument(
    BuildContext context,
    LibraryNotifier notifier,
  ) async {
    final id = await notifier.createDocument();
    if (context.mounted) {
      context.pushNamed('editor', pathParameters: {'documentId': id});
    }
  }
}
