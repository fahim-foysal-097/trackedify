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
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 2),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No data for the chart',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please add some expenses to view the chart.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ensure a safe maxY (avoid zero or negative)
    final maxDaily = dailyTotals.reduce((a, b) => a > b ? a : b);
    final computedMaxY = (maxDaily * 1.2).clamp(1.0, double.infinity);

    // Compute insights for last 7 days
    final NumberFormat currency = NumberFormat.simpleCurrency(name: 'USD');
    final double total7 = dailyTotals.fold(0.0, (a, b) => a + b);
    final double avg7 = total7 / 7.0;
    final int maxIndex = dailyTotals.indexWhere((v) => v == maxDaily);
    final DateTime? maxDay = (maxIndex >= 0 && maxIndex < last7Days.length)
        ? last7Days[maxIndex]
        : null;

    // give the bar chart a bounded height to avoid unbounded/expanding behavior
    return SizedBox(
      height: 520,
      child: Column(
        children: [
          // Last 7 days insights row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Total (7 days)
                Expanded(
                  child: _InsightCard(
                    title: 'Total (7d)',
                    value: currency.format(total7),
                    subtitle: 'Total',
                    backgroundColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(width: 8),
                // Average/day
                Expanded(
                  child: _InsightCard(
                    title: 'Avg / day',
                    value: currency.format(avg7),
                    subtitle: 'Avg (7d)',
                    backgroundColor: Colors.green.shade50,
                  ),
                ),
                const SizedBox(width: 8),
                // Highest day
                Expanded(
                  child: _InsightCard(
                    title: 'Highest day',
                    value: maxDay != null
                        ? DateFormat('MM/dd').format(maxDay)
                        : '-',
                    subtitle: currency.format(maxDaily),
                    backgroundColor: Colors.orange.shade50,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // The bar chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.transparent,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      tooltipMargin: 8,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem:
                          (
                            BarChartGroupData group,
                            int groupIndex,
                            BarChartRodData rod,
                            int rodIndex,
                          ) {
                            // Do not show tooltip if the value is 0 or less
                            if (rod.toY <= 0) return null;

                            // Format currency
                            final String amountLabel = currency.format(rod.toY);

                            return BarTooltipItem(
                              amountLabel,
                              const TextStyle(
                                color: Colors.black87,
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
                      // only show tooltip indicator for non-zero bars
                      showingTooltipIndicators: dailyTotals[i] > 0
                          ? [0]
                          : <int>[],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
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

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color backgroundColor;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
