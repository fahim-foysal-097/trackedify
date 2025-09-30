import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> last7DaysExpenses;
  const ExpenseBarChart({super.key, required this.last7DaysExpenses});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dailyTotals = {};
    for (int i = 0; i < 7; i++) {
      DateTime day = DateTime.now().subtract(Duration(days: 6 - i));
      String dayStr = DateFormat('E').format(day);
      dailyTotals[dayStr] = 0.0;
    }

    for (var e in last7DaysExpenses) {
      DateTime dt = e['date'];
      String dayStr = DateFormat('E').format(dt);
      dailyTotals[dayStr] = (dailyTotals[dayStr] ?? 0) + e['amount'];
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.yellow,
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Last 7 Days Spending",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) =>
                            Text(dailyTotals.keys.toList()[v.toInt()]),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dailyTotals.values.toList()[i],
                          color: colors[i % colors.length],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
