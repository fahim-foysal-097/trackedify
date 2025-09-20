import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:intl/intl.dart';

class MyBarChart extends StatefulWidget {
  const MyBarChart({super.key});

  @override
  State<MyBarChart> createState() => _MyBarChartState();
}

class _MyBarChartState extends State<MyBarChart> {
  List<double> dailyTotals = List.filled(7, 0);
  List<DateTime> last7Days = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final data = await db.query('expenses', orderBy: 'date ASC');

    final now = DateTime.now();
    last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    Map<String, double> totals = {};
    for (var day in last7Days) {
      totals[DateFormat('yyyy-MM-dd').format(day)] = 0;
    }

    for (var row in data) {
      final dateStr = row['date'] as String;
      final amount = (row['amount'] as num).toDouble();
      if (totals.containsKey(dateStr)) {
        totals[dateStr] = totals[dateStr]! + amount;
      }
    }

    if (mounted) {
      setState(() {
        dailyTotals = totals.values.toList();
        isLoading = false;
      });
    }
  }

  LinearGradient get _barsGradient => const LinearGradient(
    colors: [Colors.blue, Colors.cyan],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Check if all values are 0
    final hasData = dailyTotals.any((e) => e > 0);

    if (!hasData) {
      return const Center(
        child: Text(
          "No data to show",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // ensure a safe maxY (avoid zero or negative)
    final maxDaily = dailyTotals.reduce((a, b) => a > b ? a : b);
    final computedMaxY = (maxDaily * 1.2).clamp(1.0, double.infinity);

    // give the bar chart a bounded height to avoid unbounded/expanding behavior
    return SizedBox(
      height: 450,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 8,
              getTooltipItem:
                  (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                  ) {
                    return BarTooltipItem(
                      rod.toY.round().toString(),
                      const TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: getTitles,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          alignment: BarChartAlignment.spaceAround,
          maxY: computedMaxY,
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dailyTotals[i],
                  gradient: _barsGradient,
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxDaily,
                    color: Colors.grey.shade200,
                  ),
                ),
              ],
              showingTooltipIndicators: [0],
            );
          }),
        ),
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.blue[800],
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    if (value.toInt() < 0 || value.toInt() >= last7Days.length) {
      return const SizedBox.shrink();
    }

    final date = last7Days[value.toInt()];
    final text = DateFormat('MM/dd').format(date);

    return SideTitleWidget(
      meta: meta,
      space: 6,
      child: Text(text, style: style),
    );
  }
}
