import 'package:flutter/foundation.dart';

/// Background Isolate Computation Service for Chart Math & Heavy Calculations
class ChartComputationService {
  /// Offload monthly totals calculation to a background isolate
  static Future<Map<String, double>> calculateMonthlyTotals(
    List<Map<String, dynamic>> rawExpenses,
  ) {
    return compute(_computeMonthlyTotalsIsolate, rawExpenses);
  }

  /// Offload category distribution calculation to a background isolate
  static Future<Map<String, double>> calculateCategoryTotals(
    List<Map<String, dynamic>> rawExpenses,
  ) {
    return compute(_computeCategoryTotalsIsolate, rawExpenses);
  }

  /// Offload 7-day bar chart calculation to a background isolate
  static Future<List<double>> calculate7DayTotals(
    List<Map<String, dynamic>> rawExpenses,
  ) {
    return compute(_compute7DayTotalsIsolate, rawExpenses);
  }

  /// Offload trend prediction & linear regression to a background isolate
  static Future<Map<String, dynamic>> calculatePredictions(
    List<Map<String, dynamic>> rawExpenses,
  ) {
    return compute(_computePredictionsIsolate, rawExpenses);
  }
}

// ─── Top-level isolate functions ─────────────────────────────────────────────

Map<String, double> _computeMonthlyTotalsIsolate(
  List<Map<String, dynamic>> rows,
) {
  final Map<String, double> monthlyTotals = {};

  for (final row in rows) {
    final amount = (row['amount'] as num).toDouble();
    final dateStr = row['date'] as String;

    String monthKey;
    final dt = DateTime.tryParse(dateStr);
    if (dt != null) {
      monthKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
    } else {
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length >= 2) {
        monthKey = '${parts[0].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}';
      } else {
        monthKey = dateStr;
      }
    }
    monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0.0) + amount;
  }

  return monthlyTotals;
}

Map<String, double> _computeCategoryTotalsIsolate(
  List<Map<String, dynamic>> rows,
) {
  final Map<String, double> categoryTotals = {};

  for (final row in rows) {
    final category = (row['category'] ?? 'Uncategorized') as String;
    final amount = (row['amount'] as num).toDouble();
    categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
  }

  return categoryTotals;
}

List<double> _compute7DayTotalsIsolate(List<Map<String, dynamic>> rows) {
  final now = DateTime.now();
  final List<double> dailyTotals = List.filled(7, 0.0);

  for (final row in rows) {
    final dateStr = row['date'] as String;
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) continue;

    final diffDays = now.difference(dt).inDays;
    if (diffDays >= 0 && diffDays < 7) {
      // 0 = today, 6 = 6 days ago -> store in index (6 - diffDays)
      final index = 6 - diffDays;
      dailyTotals[index] += (row['amount'] as num).toDouble();
    }
  }

  return dailyTotals;
}

Map<String, dynamic> _computePredictionsIsolate(
  List<Map<String, dynamic>> rows,
) {
  final monthlyTotals = _computeMonthlyTotalsIsolate(rows);
  if (monthlyTotals.length < 2) {
    return {
      'predictedNextMonth': 0.0,
      'trendSlope': 0.0,
      'monthlyTotals': monthlyTotals,
    };
  }

  final sortedMonths = monthlyTotals.keys.toList()..sort();
  final values = sortedMonths.map((m) => monthlyTotals[m]!).toList();
  final n = values.length;

  double sumX = 0;
  double sumY = 0;
  double sumXY = 0;
  double sumXX = 0;

  for (int i = 0; i < n; i++) {
    final x = i.toDouble();
    final y = values[i];
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumXX += x * x;
  }

  final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  final intercept = (sumY - slope * sumX) / n;
  final predictedNext = (slope * n + intercept).clamp(0.0, double.infinity);

  return {
    'predictedNextMonth': predictedNext,
    'trendSlope': slope,
    'monthlyTotals': monthlyTotals,
  };
}
