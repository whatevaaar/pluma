import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/features/settings/data/settings_repository_impl.dart';
import 'package:pluma/features/settings/presentation/app_version_provider.dart';
import 'package:pluma/features/settings/presentation/settings_screen.dart';

import '../../../shared/fakes/fake_settings_repository.dart';

/// Regression test for the "Acerca de" version: it must reflect the real
/// shipped version (via [appVersionProvider] → PackageInfo), not a hardcoded
/// literal. Overriding the provider must change what the UI shows.
void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    required String version,
  }) async {
    // The "Acerca de" card is the last child of a lazy ListView; make the
    // viewport tall enough that it is built and laid out without scrolling.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fake = FakeSettingsRepository();
    addTearDown(fake.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWith((_) async => fake),
          appVersionProvider.overrideWith((_) async => version),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('About shows the version from appVersionProvider',
      (tester) async {
    await pumpSettings(tester, version: 'v9.9.9');

    expect(find.text('Pluma v9.9.9'), findsOneWidget);
    // The old hardcoded value must be gone.
    expect(find.text('Pluma v0.1.0'), findsNothing);
  });

  testWidgets('About version tracks a different provider value',
      (tester) async {
    await pumpSettings(tester, version: 'v0.1.42');

    expect(find.text('Pluma v0.1.42'), findsOneWidget);
  });
}
