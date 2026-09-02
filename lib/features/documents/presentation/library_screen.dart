import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/documents/domain/document_repository.dart';
import 'package:pluma/features/documents/domain/project.dart';
import 'package:pluma/features/documents/presentation/library_notifier.dart';
import 'package:pluma/features/documents/presentation/widgets/document_tile.dart';
import 'package:pluma/features/documents/presentation/widgets/project_card.dart';
import 'package:pluma/features/import/data/document_importer.dart';
import 'package:pluma/shared/widgets/empty_state.dart';
import 'package:pluma/shared/widgets/section_header.dart';

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
    final libraryAsync = ref.watch(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);

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
            : const Text('Escritos'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  unawaited(notifier.search(''));
                }
              });
            },
          ),
          if (!_showSearch)
            libraryAsync.whenData((state) {
              return IconButton(
                icon: const Icon(Icons.sort),
                tooltip: 'Ordenar',
                onPressed: () =>
                    _showSortSheet(context, state.sortOrder, notifier),
              );
            }).value ??
                const SizedBox.shrink(),
          if (!_showSearch)
            PopupMenuButton<_MenuAction>(
              onSelected: (action) => _onMenuAction(context, action, notifier),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MenuAction.newProject,
                  child: ListTile(
                    leading: Icon(Icons.create_new_folder_outlined),
                    title: Text('Nueva carpeta'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MenuAction.importDocument,
                  child: ListTile(
                    leading: Icon(Icons.file_upload_outlined),
                    title: Text('Importar TXT / Markdown'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _MenuAction.trash,
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Papelera'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final isSearching = state.searchQuery.isNotEmpty;
          final docs = isSearching ? state.searchResults : state.documents;

          if (!isSearching && docs.isEmpty && state.projects.isEmpty) {
            return EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'Tu historia empieza aquí',
              subtitle: 'Crea tu primer documento y empieza a escribir.',
              actionLabel: 'Crear documento',
              action: () => _createAndOpen(context, notifier),
            );
          }

          return CustomScrollView(
            slivers: [
              // Projects section
              if (!isSearching && state.projects.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    label: 'Carpetas',
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.projects.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final project = state.projects[i];
                        final count = state.documents
                            .where((d) => d.projectId == project.id)
                            .length;
                        return ProjectCard(
                          project: project,
                          documentCount: count,
                          onTap: () => context.pushNamed(
                            'project',
                            pathParameters: {'projectId': project.id},
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    label: 'Documentos',
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  ),
                ),
              ],

              // Documents list
              if (docs.isEmpty && isSearching)
                const SliverFillRemaining(
                  child: Center(child: Text('Sin resultados')),
                )
              else
                SliverList.separated(
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    return DocumentTile(
                      document: doc,
                      onTap: () => context.pushNamed(
                        'editor',
                        pathParameters: {'documentId': doc.id},
                      ),
                      onFavoriteTap: () => notifier.toggleFavorite(doc.id),
                      onMenuTap: () => _showDocumentMenu(
                        context,
                        doc,
                        state.projects,
                        notifier,
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('new_document_fab'),
        onPressed: () => unawaited(_createAndOpen(context, notifier)),
        tooltip: 'Nuevo documento',
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Future<void> _createAndOpen(
    BuildContext context,
    LibraryNotifier notifier,
  ) async {
    final id = await notifier.createDocument();
    if (context.mounted) {
      unawaited(
        context.pushNamed('editor', pathParameters: {'documentId': id}),
      );
    }
  }

  void _onMenuAction(
    BuildContext context,
    _MenuAction action,
    LibraryNotifier notifier,
  ) {
    switch (action) {
      case _MenuAction.newProject:
        _showNewProjectDialog(context, notifier);
      case _MenuAction.importDocument:
        unawaited(_importAndOpen(context, notifier));
      case _MenuAction.trash:
        unawaited(context.pushNamed('trash'));
    }
  }

  Future<void> _importAndOpen(
    BuildContext context,
    LibraryNotifier notifier,
  ) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'markdown'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    try {
      final bytes = await file.readAsBytes();
      final imported = parseImportedFile(
        filename: file.name,
        raw: utf8.decode(bytes),
      );
      final id = await notifier.importDocument(imported);
      if (!context.mounted) return;
      unawaited(
        context.pushNamed('editor', pathParameters: {'documentId': id}),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo importar el archivo.')),
      );
    }
  }

  void _showSortSheet(
    BuildContext context,
    SortOrder current,
    LibraryNotifier notifier,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Ordenar por',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final (order, label) in _sortOptions)
                ListTile(
                  title: Text(label),
                  trailing: current == order
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    notifier.setSortOrder(order);
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

  void _showDocumentMenu(
    BuildContext context,
    Document doc,
    List<Project> projects,
    LibraryNotifier notifier,
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
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Renombrar'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(context, doc, notifier);
                },
              ),
              ListTile(
                leading: Icon(
                  doc.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                ),
                title: Text(
                  doc.isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                ),
                onTap: () {
                  unawaited(notifier.toggleFavorite(doc.id));
                  Navigator.pop(context);
                },
              ),
              if (projects.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Mover a carpeta'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMoveSheet(context, doc, projects, notifier);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Mover a papelera',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  unawaited(notifier.deleteDocument(doc.id));
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

  void _showRenameDialog(
    BuildContext context,
    Document doc,
    LibraryNotifier notifier,
  ) {
    final controller = TextEditingController(text: doc.title);
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Renombrar'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Título del documento',
            ),
            onSubmitted: (v) {
              unawaited(notifier.renameDocument(doc.id, v.trim()));
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                unawaited(
                  notifier.renameDocument(
                    doc.id,
                    controller.text.trim(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveSheet(
    BuildContext context,
    Document doc,
    List<Project> projects,
    LibraryNotifier notifier,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Mover a carpeta',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (doc.projectId != null)
                ListTile(
                  leading: const Icon(Icons.folder_off_outlined),
                  title: const Text('Sin carpeta'),
                  onTap: () {
                    unawaited(notifier.moveDocument(doc.id, null));
                    Navigator.pop(context);
                  },
                ),
              for (final p in projects)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p.name),
                  trailing: doc.projectId == p.id
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    unawaited(notifier.moveDocument(doc.id, p.id));
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

  void _showNewProjectDialog(BuildContext context, LibraryNotifier notifier) {
    final controller = TextEditingController();
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nueva carpeta'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'Nombre de la carpeta'),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                unawaited(notifier.createProject(v.trim()));
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  unawaited(
                    notifier.createProject(controller.text.trim()),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MenuAction { newProject, importDocument, trash }

const List<(SortOrder, String)> _sortOptions = [
  (SortOrder.updatedDesc, 'Modificado (reciente primero)'),
  (SortOrder.updatedAsc, 'Modificado (antiguo primero)'),
  (SortOrder.createdDesc, 'Creado (reciente primero)'),
  (SortOrder.titleAsc, 'Título (A-Z)'),
  (SortOrder.wordCountDesc, 'Palabras (más primero)'),
];
