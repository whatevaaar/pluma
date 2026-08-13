import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pluma/features/documents/domain/document.dart';
import 'package:pluma/features/trash/presentation/trash_notifier.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trashProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Papelera'),
        actions: [
          state.maybeWhen(
            data: (docs) => docs.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmEmptyTrash(context, ref),
                    child: Text(
                      'Vaciar',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
            orElse: SizedBox.shrink,
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) => docs.isEmpty
            ? _EmptyTrashState()
            : _TrashList(docs: docs),
      ),
    );
  }

  Future<void> _confirmEmptyTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Vaciar papelera?'),
        content: const Text(
          'Se eliminarán permanentemente todos los documentos. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(trashProvider.notifier).emptyTrash();
    }
  }
}

class _EmptyTrashState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'La papelera está vacía',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Los documentos eliminados aparecen aquí\nhasta 30 días antes de borrarse.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _TrashList extends ConsumerWidget {
  const _TrashList({required this.docs});

  final List<Document> docs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, i) => _TrashTile(
        doc: docs[i],
        onRestore: () =>
            ref.read(trashProvider.notifier).restore(docs[i].id),
        onDeletePermanently: () =>
            _confirmDelete(context, ref, docs[i]),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Document doc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar definitivamente'),
        content: Text(
          '¿Eliminar "${doc.displayTitle}" de forma permanente? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(trashProvider.notifier).deletePermanently(doc.id);
    }
  }
}

class _TrashTile extends StatelessWidget {
  const _TrashTile({
    required this.doc,
    required this.onRestore,
    required this.onDeletePermanently,
  });

  final Document doc;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deletedLabel = doc.deletedAt != null
        ? 'Eliminado el ${DateFormat('d MMM y', 'es').format(doc.deletedAt!)}'
        : 'Eliminado';

    return Dismissible(
      key: ValueKey(doc.id),
      background: _SwipeBackground(
        color: colorScheme.primaryContainer,
        icon: Icons.restore,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _SwipeBackground(
        color: colorScheme.errorContainer,
        icon: Icons.delete_forever,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onRestore();
          return false;
        } else {
          onDeletePermanently();
          return false;
        }
      },
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          Icons.insert_drive_file_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        title: Text(
          doc.displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$deletedLabel · ${doc.wordCount} palabras',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<_TrashAction>(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
          onSelected: (action) {
            switch (action) {
              case _TrashAction.restore:
                onRestore();
              case _TrashAction.delete:
                onDeletePermanently();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _TrashAction.restore,
              child: ListTile(
                leading: Icon(Icons.restore),
                title: Text('Restaurar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _TrashAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_forever),
                title: Text('Eliminar definitivamente'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Icon(icon),
    );
  }
}

enum _TrashAction { restore, delete }
