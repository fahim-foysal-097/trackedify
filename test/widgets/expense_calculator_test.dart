import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/views/pages/calculator.dart';

void main() {
  Widget buildCalculator({required ValueChanged<double> onResult}) {
    return MaterialApp(
      home: Scaffold(body: ExpenseCalculator(onResult: onResult)),
    );
  }

  Finder btn(String text) => find.widgetWithText(InkWell, text);

  group('ExpenseCalculator Widget Tests', () {
    testWidgets('renders calculator keypad properly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCalculator(onResult: (_) {}));

      expect(btn('C'), findsOneWidget);
      expect(btn('⌫'), findsOneWidget);
      expect(btn('='), findsOneWidget);
      expect(btn('7'), findsOneWidget);
      expect(btn('+'), findsOneWidget);
      expect(btn('%'), findsOneWidget);
    });

    testWidgets('performs addition calculation (7 + 8 = 15.00)', (
      WidgetTester tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        buildCalculator(
          onResult: (val) {
            result = val;
          },
        ),
      );

      await tester.tap(btn('7'));
      await tester.pump();

      await tester.tap(btn('+'));
      await tester.pump();

      await tester.tap(btn('8'));
      await tester.pump();

      await tester.tap(btn('='));
      await tester.pump();

      expect(find.text('15.00'), findsWidgets);
      expect(result, equals(15.0));
    });

    testWidgets('performs multiplication calculation (5 × 6 = 30.00)', (
      WidgetTester tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        buildCalculator(
          onResult: (val) {
            result = val;
          },
        ),
      );

      await tester.tap(btn('5'));
      await tester.pump();

      await tester.tap(btn('×'));
      await tester.pump();

      await tester.tap(btn('6'));
      await tester.pump();

      await tester.tap(btn('='));
      await tester.pump();

      expect(find.text('30.00'), findsWidgets);
      expect(result, equals(30.0));
    });

    testWidgets(
      'handles percentage calculation on percentage button tap (e.g. 50% = 0.50)',
      (WidgetTester tester) async {
        double? result;

        await tester.pumpWidget(
          buildCalculator(
            onResult: (val) {
              result = val;
            },
          ),
        );

        await tester.tap(btn('5'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();

        // Tap % (calculates percentage automatically)
        await tester.tap(btn('%'));
        await tester.pump();

        expect(find.text('0.50'), findsWidgets);
        expect(result, equals(0.50));
      },
    );

    testWidgets(
      'handles additive percentage calculation (100 + 20% = 120.00)',
      (WidgetTester tester) async {
        double? result;

        await tester.pumpWidget(
          buildCalculator(
            onResult: (val) {
              result = val;
            },
          ),
        );

        // Type 100
        await tester.tap(btn('1'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();

        // Type +
        await tester.tap(btn('+'));
        await tester.pump();

        // Type 20
        await tester.tap(btn('2'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();

        // Tap %
        await tester.tap(btn('%'));
        await tester.pump();

        expect(find.text('120.00'), findsWidgets);
        expect(result, equals(120.0));
      },
    );

    testWidgets(
      'handles subtractive percentage calculation (100 - 20% = 80.00)',
      (WidgetTester tester) async {
        double? result;

        await tester.pumpWidget(
          buildCalculator(
            onResult: (val) {
              result = val;
            },
          ),
        );

        // Type 100
        await tester.tap(btn('1'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();

        // Type -
        await tester.tap(btn('-'));
        await tester.pump();

        // Type 20
        await tester.tap(btn('2'));
        await tester.pump();
        await tester.tap(btn('0'));
        await tester.pump();

        // Tap %
        await tester.tap(btn('%'));
        await tester.pump();

        expect(find.text('80.00'), findsWidgets);
        expect(result, equals(80.0));
      },
    );

    testWidgets('clear button resets calculation state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCalculator(onResult: (_) {}));

      await tester.tap(btn('9'));
      await tester.pump();

      expect(find.text('9'), findsWidgets);

      await tester.tap(btn('C'));
      await tester.pump();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('delete backspace button removes last character', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildCalculator(onResult: (_) {}));

      await tester.tap(btn('1'));
      await tester.pump();
      await tester.tap(btn('2'));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);

      await tester.tap(btn('⌫'));
      await tester.pump();

      expect(find.text('1'), findsWidgets);
    });
  });
}
