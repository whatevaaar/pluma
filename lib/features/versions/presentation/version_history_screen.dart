import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/core/extensions/datetime_ext.dart';
import 'package:pluma/features/editor/presentation/editor_notifier.dart';
import 'package:pluma/features/versions/data/versions_repository_impl.dart';
import 'package:pluma/features/versions/domain/document_version.dart';
import 'package:pluma/features/versions/presentation/versions_notifier.dart';
import 'package:pluma/shared/widgets/empty_state.dart';

/// Lists a document's saved versions and lets the user preview, restore or
/// delete them. Pushed on top of the editor via [Navigator], so the
/// `editorProvider(documentId)` it restores into stays alive.
class VersionHistoryScreen extends ConsumerWidget {
  const VersionHistoryScreen({required this.documentId, super.key});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(documentVersionsProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de versiones')),
      body: versionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar versiones: $e')),
        data: (versions) {
          if (versions.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: 'Aún no hay versiones',
              subtitle:
                  'Pluma guarda una versión al terminar cada sesión de '
                  'escritura. También puedes guardar una manualmente.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: versions.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, i) => _VersionTile(
              documentId: documentId,
              version: versions[i],
              isLatest: i == 0,
            ),
          );
        },
      ),
    );
  }
}

class _VersionTile extends ConsumerWidget {
  const _VersionTile({
    required this.documentId,
    required this.version,
    required this.isLatest,
  });

  final String documentId;
  final DocumentVersion version;
  final bool isLatest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(_formatTimestamp(version.createdAt), style: tt.bodyLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Badge(label: version.reasonLabel),
            if (isLatest) const _Badge(label: 'Actual', highlight: true),
            Text(
              '${version.wordCount} palabras',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      onTap: () => _openPreview(context),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (action) async {
          switch (action) {
            case 'restore':
              await _confirmAndRestore(context, ref);
            case 'delete':
              await ref
                  .read(versionsRepositoryProvider)
                  .deleteById(version.id);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'restore', child: Text('Restaurar')),
          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _VersionPreviewScreen(
          documentId: documentId,
          version: version,
        ),
      ),
    );
  }

  Future<void> _confirmAndRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar versión'),
        content: Text(
          'El contenido actual se reemplazará por esta versión del '
          '${_formatTimestamp(version.createdAt)}. Guardaremos primero una '
          'copia del contenido actual, así que podrás deshacerlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(editorProvider(documentId).notifier)
        .restoreVersion(version);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // back to the editor
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Versión restaurada')),
    );
  }
}

/// Read-only render of a version's content, with a restore action.
class _VersionPreviewScreen extends ConsumerWidget {
  const _VersionPreviewScreen({
    required this.documentId,
    required this.version,
  });

  final String documentId;
  final DocumentVersion version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = _buildReadOnlyController(version.content);

    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa')),
      body: quill.QuillEditor.basic(
        controller: controller,
        config: const quill.QuillEditorConfig(
          padding: EdgeInsets.all(20),
          showCursor: false,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.restore),
        label: const Text('Restaurar'),
        onPressed: () async {
          await ref
              .read(editorProvider(documentId).notifier)
              .restoreVersion(version);
          if (!context.mounted) return;
          // Pop the preview and the history screen back to the editor.
          Navigator.of(context)
            ..pop()
            ..pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Versión restaurada')),
          );
        },
      ),
    );
  }

  quill.QuillController _buildReadOnlyController(String deltaJson) {
    try {
      final ops =
          (jsonDecode(deltaJson) as Map<String, dynamic>)['ops'] as List;
      return quill.QuillController(
        document: quill.Document.fromJson(ops),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    } on Object catch (_) {
      return quill.QuillController.basic()..readOnly = true;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg =
        highlight ? cs.primary.withAlpha(30) : cs.surfaceContainerHighest;
    final fg = highlight ? cs.primary : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

String _formatTimestamp(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final day = dt.isToday
      ? 'Hoy'
      : dt.isYesterday
          ? 'Ayer'
          : dt.toSpanishMediumDate();
  return '$day · $h:$m';
}
