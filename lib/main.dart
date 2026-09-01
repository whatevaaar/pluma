import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:pluma/app.dart';
import 'package:pluma/core/database/app_database.dart';
import 'package:pluma/features/reminders/presentation/reminder_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts come from bundle only — never fetched from the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  await Hive.initFlutter();

  final database = AppDatabase();
  await database.trashDao.purgeExpiredTrash();

  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
    ],
  );

  // Reconcile the daily reminder's OS schedule with the saved preference
  // (pending notifications are cleared on reboot / app update).
  unawaited(
    container.read(reminderControllerProvider.notifier).syncOnStartup(),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PlumaApp(),
    ),
  );
}
