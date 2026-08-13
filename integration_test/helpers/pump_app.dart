import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/app.dart';
import 'package:pluma/core/database/app_database.dart';

extension WidgetTesterPumpApp on WidgetTester {
  /// Pumps PlumaApp with the given database override.
  /// Use this in every integration test to get a consistent app shell.
  Future<void> pumpApp(AppDatabase database) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const PlumaApp(),
      ),
    );
    await pumpAndSettle();
  }
}
