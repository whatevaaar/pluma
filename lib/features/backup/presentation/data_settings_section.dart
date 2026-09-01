import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pluma/features/backup/data/backup_service.dart';
import 'package:pluma/features/backup/domain/backup_exceptions.dart';
import 'package:pluma/features/settings/presentation/app_version_provider.dart';

/// "Datos" settings block: create a full-library backup or restore one.
class DataSettingsSection extends ConsumerStatefulWidget {
  const DataSettingsSection({super.key});

  @override
  ConsumerState<DataSettingsSection> createState() =>
      _DataSettingsSectionState();
}

class _DataSettingsSectionState extends ConsumerState<DataSettingsSection> {
  bool _busy = false;

  String get _appVersion => ref.read(appVersionProvider).value ?? 'v0';

  Future<void> _run(Future<void> Function(BackupService service) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      await action(service);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createBackup() => _run((service) async {
        try {
          await service.shareBackup(appVersion: _appVersion);
        } on Object {
          _snack('No se pudo crear la copia de seguridad.');
        }
      });

  Future<void> _restoreBackup() => _run((service) async {
        final result = await FilePicker.pickFiles();
        if (result == null || result.files.isEmpty) return; // cancelled
        final bytes = await result.files.first.readAsBytes();

        final BackupSummary summary;
        try {
          summary = service.parseBackup(utf8.decode(bytes));
        } on BackupFormatException catch (e) {
          _snack(e.message);
          return;
        } on Object {
          _snack('No se pudo leer el archivo.');
          return;
        }

        if (!mounted) return;
        final confirmed = await _confirmRestore(summary);
        if (confirmed != true) return;

        try {
          // Safety net: back up the current library before wiping it.
          await service.writeSafetyBackup(appVersion: _appVersion);
          await service.restore(summary.data);
          _snack('Biblioteca restaurada.');
        } on Object {
          _snack('No se pudo restaurar la copia.');
        }
      });

  Future<bool?> _confirmRestore(BackupSummary summary) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar copia'),
        content: Text(
          'Se reemplazará toda tu biblioteca actual por esta copia '
          '(${summary.documentCount} documentos, ${summary.projectCount} '
          'proyectos). Guardaremos primero una copia de tu biblioteca actual '
          'en el dispositivo. Esta acción no se puede deshacer fácilmente.',
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
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text('Crear copia de seguridad', style: tt.bodyMedium),
            subtitle: Text(
              'Guarda toda tu biblioteca en un archivo',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            trailing: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _busy ? null : _createBackup,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text('Restaurar desde una copia', style: tt.bodyMedium),
            subtitle: Text(
              'Reemplaza tu biblioteca con una copia guardada',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            onTap: _busy ? null : _restoreBackup,
          ),
        ],
      ),
    );
  }
}
