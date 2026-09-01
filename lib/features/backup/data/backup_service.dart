import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/core/extensions/datetime_ext.dart';
import 'package:pluma/features/backup/data/backup_dao.dart';
import 'package:pluma/features/backup/domain/backup_exceptions.dart';
import 'package:pluma/features/settings/data/settings_repository_impl.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/domain/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'backup_service.g.dart';

/// Summary of a parsed backup, shown in the restore confirmation dialog.
class BackupSummary {
  const BackupSummary({
    required this.data,
    required this.projectCount,
    required this.documentCount,
    this.createdAt,
  });

  final Map<String, dynamic> data;
  final int projectCount;
  final int documentCount;
  final DateTime? createdAt;
}

/// Builds and restores a full, lossless library backup as a single JSON file.
///
/// The backup travels wherever the user shares it — no server is involved, in
/// keeping with Pluma's offline-only promise.
class BackupService {
  BackupService(this._dao, this._settings);

  final BackupDao _dao;
  final SettingsRepository _settings;

  static const backupFormat = 'pluma-backup';
  static const backupSchemaVersion = 1;

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  /// Assembles the full backup as a JSON-serializable map. Pure — no IO.
  Future<Map<String, dynamic>> buildBackup({required String appVersion}) async {
    final projects = await _dao.getAllProjects();
    final documents = await _dao.getAllDocuments();
    final dailyStats = await _dao.getAllDailyStats();
    final settings = await _settings.getSettings();

    return {
      'format': backupFormat,
      'version': backupSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'appVersion': appVersion,
      'counts': {
        'projects': projects.length,
        'documents': documents.length,
      },
      'projects': projects.map((r) => r.toJson()).toList(),
      'documents': documents.map((r) => r.toJson()).toList(),
      'dailyStats': dailyStats.map((r) => r.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  /// Writes the backup to a temp file and opens the system share sheet so the
  /// user can save it to Files / iCloud / Drive / etc.
  Future<void> shareBackup({required String appVersion}) async {
    final json = jsonEncode(await buildBackup(appVersion: appVersion));
    final filename = 'pluma-backup-${DateTime.now().toDateKey}.plumabak';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  /// Writes a safety backup of the CURRENT library to the app documents
  /// directory before a destructive restore, so it is always recoverable.
  Future<void> writeSafetyBackup({required String appVersion}) async {
    final json = jsonEncode(await buildBackup(appVersion: appVersion));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pluma-pre-restore-backup.plumabak');
    await file.writeAsString(json);
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Parses and validates a backup file's contents. Throws
  /// [BackupFormatException] if it isn't a supported Pluma backup.
  BackupSummary parseBackup(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupFormatException('El archivo no es un JSON válido.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException('Formato de copia no reconocido.');
    }
    if (decoded['format'] != backupFormat) {
      throw const BackupFormatException(
        'Este archivo no es una copia de Pluma.',
      );
    }
    final version = decoded['version'];
    if (version is! int || version > backupSchemaVersion) {
      throw const BackupFormatException(
        'Esta copia se creó con una versión más nueva de Pluma.',
      );
    }
    return BackupSummary(
      data: decoded,
      projectCount: (decoded['projects'] as List?)?.length ?? 0,
      documentCount: (decoded['documents'] as List?)?.length ?? 0,
      createdAt: DateTime.tryParse(decoded['createdAt'] as String? ?? ''),
    );
  }

  /// Replaces the entire library with the backup's contents, then restores
  /// settings. Destructive — callers must confirm and write a safety backup
  /// first.
  Future<void> restore(Map<String, dynamic> data) async {
    final projectRows =
        _decodeRows(data['projects'], ProjectRow.fromJson);
    final documentRows =
        _decodeRows(data['documents'], DocumentRow.fromJson);
    final dailyStatRows =
        _decodeRows(data['dailyStats'], DailyStat.fromJson);

    await _dao.replaceAll(
      projectRows: projectRows,
      documentRows: documentRows,
      dailyStatRows: dailyStatRows,
    );

    final settingsJson = data['settings'];
    if (settingsJson is Map<String, dynamic>) {
      await _settings.saveSettings(AppSettings.fromJson(settingsJson));
    }
  }

  List<T> _decodeRows<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw
        .map((e) => fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

@riverpod
Future<BackupService> backupService(Ref ref) async {
  final settings = await ref.watch(settingsRepositoryProvider.future);
  return BackupService(ref.watch(backupDaoProvider), settings);
}
