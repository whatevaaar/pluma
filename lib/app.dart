import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pluma/core/router/app_router.dart';
import 'package:pluma/core/theme/app_theme.dart';
import 'package:pluma/features/settings/domain/app_settings.dart';
import 'package:pluma/features/settings/presentation/settings_notifier.dart';

class PlumaApp extends ConsumerWidget {
  const PlumaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pluma',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings),
      darkTheme: AppTheme.dark(settings),
      themeMode: settings.themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        // Required by flutter_quill's standalone toolbar buttons: they call
        // context.loc during build and throw MissingFlutterQuillLocalization
        // if this delegate is absent — which renders as a blank gray bar in
        // release mode (the default ErrorWidget).
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
    );
  }
}
