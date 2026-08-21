import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/app.dart';
import 'package:pluma/features/editor/presentation/widgets/writing_toolbar.dart';

/// Regression tests for the "gray toolbar" bug.
///
/// The editor toolbar rendered as a blank gray bar in release builds because
/// flutter_quill's toolbar buttons call `context.loc` during build, which
/// throws when [FlutterQuillLocalizations.delegate] is not registered. In
/// release, a build-time exception is drawn as the default gray ErrorWidget.
///
/// These tests lock in that:
///   1. The app keeps the required localizations delegate registered.
///   2. [WritingToolbar] actually renders its buttons (no exception) under the
///      app's real delegate list — so removing the delegate from
///      [PlumaApp.localizationsDelegates] makes test 2 fail.
void main() {
  QuillController makeController() {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);
    return controller;
  }

  Widget wrap(
    Widget child, {
    required List<LocalizationsDelegate<dynamic>> delegates,
  }) {
    return MaterialApp(
      localizationsDelegates: delegates,
      supportedLocales: PlumaApp.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets(
    'PlumaApp registers FlutterQuillLocalizations delegate',
    (tester) async {
      expect(
        PlumaApp.localizationsDelegates,
        contains(FlutterQuillLocalizations.delegate),
      );
    },
  );

  testWidgets(
    'renders formatting buttons under the app localizations delegates',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          WritingToolbar(controller: makeController()),
          delegates: PlumaApp.localizationsDelegates,
        ),
      );
      await tester.pumpAndSettle();

      // No build-time exception (which would render as the gray ErrorWidget).
      expect(tester.takeException(), isNull);
      // The curated buttons are actually present.
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
    },
  );
}
