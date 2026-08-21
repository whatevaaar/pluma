import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluma/shared/widgets/poem_view.dart';

void main() {
  group('PoemView.computeFontSize', () {
    double fit({
      double maxWidth = 1000,
      double maxHeight = 1000,
      List<double> lines = const [50],
      double titleRef = 0,
      bool hasTitle = false,
      double min = 6,
      double max = 100,
      double lineHeight = 1.4,
    }) {
      return PoemView.computeFontSize(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        lineRefWidths: lines,
        titleRefWidth: titleRef,
        hasTitle: hasTitle,
        minFontSize: min,
        maxFontSize: max,
        lineHeight: lineHeight,
      );
    }

    test('caps at maxFontSize when the content fits easily', () {
      expect(fit(lines: const [10]), 100);
    });

    test('shrinks so the widest line fits the width', () {
      // A line 500 wide at the reference size 100 is 5×fontSize wide;
      // in a 250-wide box that means fontSize == 50.
      expect(
        fit(maxWidth: 250, lines: const [500], maxHeight: 100000),
        closeTo(50, 0.001),
      );
    });

    test('shrinks to fit the height and clamps to minFontSize', () {
      final lines = List<double>.filled(50, 10);
      expect(fit(lines: lines, maxHeight: 280, maxWidth: 100000), 6);
    });

    test('a narrower width never yields a larger font', () {
      final wide = fit(maxWidth: 400, lines: const [500], maxHeight: 100000);
      final narrow = fit(maxWidth: 200, lines: const [500], maxHeight: 100000);
      expect(narrow, lessThanOrEqualTo(wide));
    });

    test('adding a title never enlarges the fitted size', () {
      final without = fit(maxHeight: 300);
      final withTitle = fit(maxHeight: 300, hasTitle: true, titleRef: 50);
      expect(withTitle, lessThanOrEqualTo(without));
    });

    test('degenerate constraints fall back to minFontSize', () {
      expect(fit(maxWidth: 0), 6);
      expect(fit(maxHeight: -5), 6);
    });
  });

  group('PoemView widget', () {
    testWidgets('renders title and body without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: PoemView(
                body: 'rosa\nvive\nen mí',
                title: 'Flor',
                textColor: Colors.black,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Flor'), findsOneWidget);
      expect(find.text('rosa\nvive\nen mí'), findsOneWidget);
    });
  });
}
