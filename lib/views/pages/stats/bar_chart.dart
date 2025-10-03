import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:intl/intl.dart';

class MyBarChart extends StatefulWidget {
  const MyBarChart({super.key});

  @override
  State<MyBarChart> createState() => MyBarChartState();
}

class MyBarChartState extends State<MyBarChart> {
  List<double> dailyTotals = List.filled(7, 0);
  List<DateTime> last7Days = [];
  bool isLoading = true;

  int totalTransactions7 = 0;
  int activeDays7 = 0;
  double largestSingleExpense7 = 0.0;
  String? largestSingleCategory7;
  Map<String, int> categoryCounts7 = {};
  String? mostUsedCategory7;
  int mostUsedCategoryCount7 = 0;
  double avgPerTransaction7 = 0.0;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final allData = await db.query('expenses', orderBy: 'date ASC');

    final now = DateTime.now();
    last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    Map<String, double> totals = {};
    for (var day in last7Days) {
      totals[DateFormat('yyyy-MM-dd').format(day)] = 0;
    }

    // Filter expenses for last 7 days
    final List<Map<String, dynamic>> recentExpenses = [];
    for (var row in allData) {
      final dateStr = row['date'] as String;
      if (totals.containsKey(dateStr)) {
        final amount = (row['amount'] as num).toDouble();
        totals[dateStr] = totals[dateStr]! + amount;
        recentExpenses.add(row);
      }
    }

    // Compute additional stats
    int txCount7 = 0;
    Map<String, int> catCounts7 = {};
    double maxSingle7 = 0.0;
    String? maxCat7;

    for (var row in recentExpenses) {
      final category = row['category'] as String;
      final amount = (row['amount'] as num).toDouble();

      txCount7 += 1;
      catCounts7[category] = (catCounts7[category] ?? 0) + 1;

      if (amount > maxSingle7) {
        maxSingle7 = amount;
        maxCat7 = category;
      }
    }

    final double total7 = totals.values.fold(0.0, (a, b) => a + b);
    final int actDays = totals.values.where((v) => v > 0).length;
    final double avgTx7 = txCount7 > 0 ? total7 / txCount7 : 0.0;

    String? mostUsedCat;
    int mostUsedCount = 0;
    if (catCounts7.isNotEmpty) {
      final maxEntry = catCounts7.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostUsedCat = maxEntry.key;
      mostUsedCount = maxEntry.value;
    }

    if (mounted) {
      setState(() {
        dailyTotals = totals.values.toList();
        totalTransactions7 = txCount7;
        activeDays7 = actDays;
        largestSingleExpense7 = maxSingle7;
        largestSingleCategory7 = maxCat7;
        categoryCounts7 = catCounts7;
        mostUsedCategory7 = mostUsedCat;
        mostUsedCategoryCount7 = mostUsedCount;
        avgPerTransaction7 = avgTx7;
        isLoading = false;
      });
    }
  }

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
                Center(
                  child: Text(
                    'Please add some expenses to view the chart.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
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

    // Stat cards for last 7 days
    List<Widget> statCards = [
      _buildStatCard(
        icon: Icons.receipt_long,
        title: 'Transactions',
        value: totalTransactions7.toString(),
        color: Colors.blue,
      ),
      _buildStatCard(
        icon: Icons.event_available,
        title: 'Active Days',
        value: activeDays7.toString(),
        color: Colors.green,
      ),
      _buildStatCard(
        icon: Icons.warning_rounded,
        title: 'Largest Single',
        value: largestSingleCategory7 ?? 'None',
        subValue: '\$${largestSingleExpense7.toStringAsFixed(2)}',
        color: Colors.red,
      ),
      _buildStatCard(
        icon: Icons.cached_rounded,
        title: 'Most Used Category',
        value: mostUsedCategory7 ?? 'None',
        subValue: '$mostUsedCategoryCount7 tx',
        color: Colors.purple,
      ),
      _buildStatCard(
        icon: Icons.trending_up,
        title: 'Avg per Tx',
        value: '\$${avgPerTransaction7.toStringAsFixed(2)}',
        color: Colors.orange,
      ),
      _buildStatCard(
        icon: Icons.analytics,
        title: 'Avg per Day',
        value: '\$${avg7.toStringAsFixed(2)}',
        color: Colors.cyan,
      ),
    ];

    // give the bar chart a bounded height to avoid unbounded/expanding behavior
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Last 7 days insights row
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                // Total (7 days)
                Expanded(
                  child: _InsightCard(
                    title: 'Total',
                    value: currency.format(total7),
                    subtitle: '7d',
                    backgroundColor: Colors.blue.shade100,
                  ),
                ),
                const SizedBox(width: 8),
                // Average/day
                Expanded(
                  child: _InsightCard(
                    title: 'Avg / day',
                    value: currency.format(avg7),
                    subtitle: '7d',
                    backgroundColor: Colors.green.shade100,
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
                    subtitle: "7d",
                    backgroundColor: Colors.orange.shade100,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Last 7 days
          SizedBox(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: (computedMaxY <= 0) ? 50.0 : computedMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (computedMaxY / 5).ceilToDouble(),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.18),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, meta) =>
                            getTitles(value, meta),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: (computedMaxY / 4).ceilToDouble(),
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(dailyTotals.length, (i) {
                        return FlSpot(i.toDouble(), dailyTotals[i]);
                      }),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      isStrokeJoinRound: true,
                      isStrokeCapRound: true,
                      color: Colors.lightBlue.shade700,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3, // smaller dots
                              color: Colors.white,
                              strokeWidth: 1.2,
                              strokeColor: Colors.blue.shade700,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade300.withValues(alpha: 0.45),
                            Colors.blue.shade300.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((lineBarSpot) {
                          final x = lineBarSpot.x.toInt().clamp(
                            0,
                            dailyTotals.length - 1,
                          );
                          final daysAgo = (dailyTotals.length - 1) - x;
                          final date = DateTime.now().subtract(
                            Duration(days: daysAgo),
                          );
                          final dateStr = DateFormat(
                            'MMM d, yyyy',
                          ).format(date);
                          final y = lineBarSpot.y;
                          return LineTooltipItem(
                            '$dateStr\n\$${y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Additional insights cards grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Last 7 Days Insights',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 18),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: (MediaQuery.of(context).size.width >= 680)
                        ? 4
                        : 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  children: statCards,
                ),
                const SizedBox(height: 24),
              ],
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subValue,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subValue != null) ...[
              const SizedBox(height: 4),
              Text(
                subValue,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
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
