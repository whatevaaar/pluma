import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pluma/features/documents/data/document_repository_impl.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/documents/domain/document_repository.dart';
import 'package:pluma/features/documents/domain/project.dart';
import 'package:pluma/features/documents/presentation/widgets/document_tile.dart';
import 'package:pluma/shared/widgets/empty_state.dart';

/// Documents inside a single folder. Reads the repository stream directly (via
/// a [StreamBuilder]) rather than a dedicated provider — the view is simple and
/// short-lived, so it doesn't warrant its own notifier.
class ProjectScreen extends ConsumerWidget {
  const ProjectScreen({required this.projectId, super.key});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(documentRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: _ProjectTitle(repo: repo, projectId: projectId)),
      body: StreamBuilder<List<Document>>(
        stream: repo.watchAll(projectId: projectId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'Carpeta vacía',
              subtitle: 'Crea un documento en esta carpeta para empezar.',
              actionLabel: 'Crear documento',
              action: () => unawaited(_createAndOpen(context, repo)),
            );
          }
          return ListView.separated(
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              return DocumentTile(
                document: doc,
                onTap: () => context.pushNamed(
                  'editor',
                  pathParameters: {'documentId': doc.id},
                ),
                onFavoriteTap: () => unawaited(repo.toggleFavorite(doc.id)),
                onMenuTap: () => _showDocumentMenu(context, doc, repo),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_createAndOpen(context, repo)),
        tooltip: 'Nuevo documento',
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Future<void> _createAndOpen(
    BuildContext context,
    DocumentRepository repo,
  ) async {
    final id = await repo.create(projectId: projectId);
    if (context.mounted) {
      unawaited(
        context.pushNamed('editor', pathParameters: {'documentId': id}),
      );
    }
  }

  void _showDocumentMenu(
    BuildContext context,
    Document doc,
    DocumentRepository repo,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  doc.displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('Quitar de la carpeta'),
                onTap: () {
                  unawaited(repo.moveToProject(doc.id, null));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Mover a papelera',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  unawaited(repo.softDelete(doc.id));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolves the folder name for the app-bar title, falling back to a generic
/// label while the lookup is in flight or if the folder was just deleted.
class _ProjectTitle extends StatelessWidget {
  const _ProjectTitle({required this.repo, required this.projectId});

  final DocumentRepository repo;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Project?>(
      future: repo.findProjectById(projectId),
      builder: (context, snapshot) => Text(snapshot.data?.name ?? 'Carpeta'),
    );
  }
}
