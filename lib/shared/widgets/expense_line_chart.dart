import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> last30DaysExpenses;
  const ExpenseLineChart({super.key, required this.last30DaysExpenses});

  @override
  Widget build(BuildContext context) {
    // Fill last 30 days with 0 if no expense
    Map<int, double> dailyTotals = {};
    for (int i = 0; i < 30; i++) {
      dailyTotals[i] = 0.0;
    }

    final now = DateTime.now();
    for (var e in last30DaysExpenses) {
      DateTime dt = e['date'];
      int diff = now.difference(dt).inDays;
      if (diff < 30) {
        dailyTotals[29 - diff] = (dailyTotals[29 - diff] ?? 0) + e['amount'];
      }
    }

    final spots = List.generate(
      30,
      (i) => FlSpot(i.toDouble(), dailyTotals[i] ?? 0),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Expenses - Last 30 Days",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (v, _) => Text("${v.toInt()}"),
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha:  0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
