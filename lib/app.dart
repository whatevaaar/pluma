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

  /// Localizations delegates for the whole app.
  ///
  /// [FlutterQuillLocalizations.delegate] is REQUIRED: flutter_quill's toolbar
  /// buttons call `context.loc` during build and throw
  /// MissingFlutterQuillLocalizationException if it is absent — which renders
  /// as a blank gray bar in release mode (the default ErrorWidget). Kept as a
  /// named constant so the regression test in test/app_test.dart can assert
  /// the delegate stays registered and that WritingToolbar renders under it.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    FlutterQuillLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

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
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
    );
  }
}
