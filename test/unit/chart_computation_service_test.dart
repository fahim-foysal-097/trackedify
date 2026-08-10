import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/services/chart_computation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChartComputationService', () {
    final rawExpenses = [
      {'amount': 50.0, 'date': '2026-05-10', 'category': 'Food'},
      {'amount': 150.0, 'date': '2026-05-15', 'category': 'Shopping'},
      {'amount': 100.0, 'date': '2026-06-01', 'category': 'Food'},
      {'amount': 200.0, 'date': '2026-06-20', 'category': 'Bills'},
    ];

    test(
      'calculateMonthlyTotals correctly aggregates expenses by YYYY-MM',
      () async {
        final monthlyTotals =
            await ChartComputationService.calculateMonthlyTotals(rawExpenses);

        expect(monthlyTotals['2026-05'], equals(200.0));
        expect(monthlyTotals['2026-06'], equals(300.0));
      },
    );

    test(
      'calculateCategoryTotals correctly aggregates expenses by category',
      () async {
        final categoryTotals =
            await ChartComputationService.calculateCategoryTotals(rawExpenses);

        expect(categoryTotals['Food'], equals(150.0));
        expect(categoryTotals['Shopping'], equals(150.0));
        expect(categoryTotals['Bills'], equals(200.0));
      },
    );

    test(
      'calculate7DayTotals computes daily totals within 7-day window',
      () async {
        final now = DateTime.now();
        final todayStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final recentExpenses = [
          {'amount': 45.50, 'date': todayStr, 'category': 'Food'},
        ];

        final totals = await ChartComputationService.calculate7DayTotals(
          recentExpenses,
        );
        expect(totals.length, equals(7));
        expect(totals[6], equals(45.50)); // Index 6 is today
      },
    );

    test('calculatePredictions handles monthly trend regression', () async {
      final predictions = await ChartComputationService.calculatePredictions(
        rawExpenses,
      );

      expect(predictions['monthlyTotals'], isA<Map<String, double>>());
      expect(predictions['predictedNextMonth'], isA<double>());
      expect(predictions['trendSlope'], isA<double>());
    });

    test('calculatePredictions handles insufficient data gracefully', () async {
      final singleExpense = [
        {'amount': 50.0, 'date': '2026-05-10', 'category': 'Food'},
      ];

      final predictions = await ChartComputationService.calculatePredictions(
        singleExpense,
      );
      expect(predictions['predictedNextMonth'], equals(0.0));
      expect(predictions['trendSlope'], equals(0.0));
    });
  });
}
