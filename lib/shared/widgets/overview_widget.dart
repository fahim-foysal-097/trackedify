import 'package:flutter/material.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/database/database_helper.dart';

class OverviewWidget extends StatelessWidget {
  const OverviewWidget({super.key});

  /// Fetch total expenses, average daily, total transactions from DB
  Future<Map<String, dynamic>> _loadOverview() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('expenses');

    double totalExpenses = 0;
    Map<String, double> dailyTotals = {};

    for (var row in rows) {
      final amount = (row['amount'] as num).toDouble();
      final date = row['date'] as String;
      totalExpenses += amount;
      dailyTotals[date] = (dailyTotals[date] ?? 0) + amount;
    }

    double avgDaily = 0;
    if (dailyTotals.isNotEmpty) {
      avgDaily =
          dailyTotals.values.reduce((a, b) => a + b) / dailyTotals.length;
    }

    return {
      'totalExpenses': totalExpenses,
      'averageDaily': avgDaily,
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
        double averageDaily = 0;
        int totalTransactions = 0;

        if (snapshot.hasData) {
          totalExpenses = snapshot.data!['totalExpenses'];
          averageDaily = snapshot.data!['averageDaily'];
          totalTransactions = snapshot.data!['totalTransactions'];
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
                      '\$${totalExpenses.toStringAsFixed(2)}',
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
                      'Average Daily',
                      style: KTextstyle.smallHeaderText,
                    ),
                    const SizedBox(height: 0),
                    Text(
                      '\$${averageDaily.toStringAsFixed(2)}',
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
