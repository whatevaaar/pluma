import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:pluma/app.dart';
import 'package:pluma/core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts come from bundle only — never fetched from the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  await Hive.initFlutter();

  final database = AppDatabase();
  await database.trashDao.purgeExpiredTrash();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const PlumaApp(),
    ),
  );
}
