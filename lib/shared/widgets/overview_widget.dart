import 'package:flutter/material.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/database/database_helper.dart';

class OverviewWidget extends StatelessWidget {
  const OverviewWidget({super.key});

  /// Fetch total expenses, average monthly, total transactions from DB
  Future<Map<String, dynamic>> _loadOverview() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('expenses');

    double totalExpenses = 0;
    final Map<String, double> monthlyTotals = {};

    for (var row in rows) {
      final amount = (row['amount'] as num).toDouble();
      final dateStr = row['date'] as String;
      totalExpenses += amount;

      // Try to parse date with DateTime; fall back to splitting (e.g. "YYYY-MM-DD" or "YYYY/MM/DD")
      String monthKey;
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        // Key: "YYYY-MM"
        monthKey =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
      } else {
        // Fallback: split on common separators and take first two parts
        final parts = dateStr.split(RegExp(r'[-/]'));
        if (parts.length >= 2) {
          final year = parts[0].padLeft(4, '0');
          final month = parts[1].padLeft(2, '0');
          monthKey = '$year-$month';
        } else {
          // If all else fails use the raw date string as key (prevents crash)
          monthKey = dateStr;
        }
      }

      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
    }

    double avgMonthly = 0;
    if (monthlyTotals.isNotEmpty) {
      final totalPerMonth = monthlyTotals.values.reduce((a, b) => a + b);
      avgMonthly = totalPerMonth / monthlyTotals.length;
    }

    return {
      'totalExpenses': totalExpenses,
      'averageMonthly': avgMonthly,
      'totalTransactions': rows.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadOverview(),
      builder: (context, snapshot) {
        // Default values if DB not yet loaded
        double totalExpenses = 0;
        double averageMonthly = 0;
        int totalTransactions = 0;

        if (snapshot.hasData) {
          totalExpenses = snapshot.data!['totalExpenses'] as double;
          averageMonthly = snapshot.data!['averageMonthly'] as double;
          totalTransactions = snapshot.data!['totalTransactions'] as int;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(30, 200, 30, 20),
          child: Stack(
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    transform: const GradientRotation(3.1416 / 4),
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(50),
                      spreadRadius: 5,
                      blurRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 0, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Text(
                      '\$ ${totalExpenses.toStringAsFixed(2)}',
                      style: KTextstyle.headerText,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 140, 0, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Transactions',
                      style: KTextstyle.smallHeaderText,
                    ),
                    const SizedBox(height: 0),
                    Text(
                      '$totalTransactions',
                      style: KTextstyle.moneySmallText,
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.fromLTRB(0, 140, 20, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Average',
                      style: KTextstyle.smallHeaderText,
                    ),
                    const SizedBox(height: 0),
                    Text(
                      '\$ ${averageMonthly.toStringAsFixed(2)}',
                      style: KTextstyle.moneySmallText,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(0, 40, 20, 0),
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFd9ed92),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const SizedBox(width: 50, height: 50),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(0, 40, 50, 0),
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFb5e48c),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const SizedBox(width: 50, height: 50),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
