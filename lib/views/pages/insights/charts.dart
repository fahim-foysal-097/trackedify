import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

// -------------------- LAST 30 DAYS CHART --------------------

class Last30DaysChart extends StatelessWidget {
  final List<Map<String, dynamic>> last30DaysExpenses;
  const Last30DaysChart({super.key, required this.last30DaysExpenses});

  @override
  Widget build(BuildContext context) {
    if (last30DaysExpenses.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No data available for last 30 days chart.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    Map<int, double> dailyTotals = {for (int i = 0; i < 30; i++) i: 0.0};

    final now = DateTime.now();
    for (var e in last30DaysExpenses) {
      DateTime dt = e['date'] as DateTime;
      int diff = now.difference(dt).inDays;
      if (diff < 30 && diff >= 0) {
        dailyTotals[29 - diff] =
            (dailyTotals[29 - diff] ?? 0) + (e['amount'] as num).toDouble();
      }
    }

    final spots = List.generate(
      30,
      (i) => FlSpot(i.toDouble(), dailyTotals[i] ?? 0.0),
    );

    // Dynamic Y interval based on max value
    double maxY = dailyTotals.values.isNotEmpty
        ? dailyTotals.values.reduce((a, b) => a > b ? a : b)
        : 100.0;
    double computedTop = (maxY <= 0) ? 50.0 : maxY;
    double intervalY = (computedTop / 5).ceilToDouble();
    if (intervalY <= 0) intervalY = 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Expenses Trend - Last 30 Days",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: (computedTop <= 0) ? 50.0 : (computedTop + intervalY),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: intervalY,
                  verticalInterval: 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt().clamp(0, 29);
                        final daysAgo = 29 - index;
                        final date = now.subtract(Duration(days: daysAgo));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: intervalY,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
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
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    preventCurveOvershootingThreshold: 0,
                    isStrokeJoinRound: true,
                    isStrokeCapRound: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent.withValues(alpha: 0.5),
                          Colors.deepPurpleAccent.withValues(alpha: 0.2),
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
                        final x = lineBarSpot.x.toInt().clamp(0, 29);
                        final daysAgo = 29 - x;
                        final date = DateTime.now().subtract(
                          Duration(days: daysAgo),
                        );
                        final dateStr = DateFormat('MMM d, yyyy').format(date);
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
        ],
      ),
    );
  }
}

// -------------------- TOP CATEGORY CHART --------------------

class TopCategoryChart extends StatelessWidget {
  final Map<String, Map<String, dynamic>> categoryExpenses;
  const TopCategoryChart({super.key, required this.categoryExpenses});

  @override
  Widget build(BuildContext context) {
    if (categoryExpenses.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No data available for categories.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => (b.value['amount'] as num).compareTo(a.value['amount']));
    final topCategories = sortedEntries.take(7).toList();

    // Dynamic Y interval based on max value
    double maxY = topCategories.isNotEmpty
        ? topCategories
              .map((e) => (e.value['amount'] as num).toDouble())
              .reduce((a, b) => a > b ? a : b)
        : 100.0;
    double computedTop = (maxY <= 0) ? 50.0 : maxY;
    double intervalY = (computedTop / 5).ceilToDouble();
    if (intervalY <= 0) intervalY = 1.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Top Categories Spending",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: computedTop + intervalY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final idx = group.x.toInt();
                      final catName = (idx >= 0 && idx < topCategories.length)
                          ? topCategories[idx].key
                          : '';
                      return BarTooltipItem(
                        '$catName\n\$${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= topCategories.length) {
                          return const SizedBox();
                        }
                        final categoryName = topCategories[idx].key;
                        final shortName = categoryName.length > 6
                            ? '${categoryName.substring(0, 6)}...'
                            : categoryName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Transform.rotate(
                            angle: -0.785,
                            child: Text(
                              shortName,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: intervalY,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
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
                barGroups: topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;
                  final color = cat.value['color'] as Color;
                  final amount = (cat.value['amount'] as num).toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        color: color,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- MONTHLY COMPARISON --------------------

class MonthCompareChart extends StatefulWidget {
  final List<Map<String, dynamic>> allExpenses;
  final List<String> availableMonths;
  const MonthCompareChart({
    super.key,
    required this.allExpenses,
    required this.availableMonths,
  });

  @override
  State<MonthCompareChart> createState() => _MonthCompareChartState();
}

class _MonthCompareChartState extends State<MonthCompareChart> {
  late String selectedMonth1;
  late String selectedMonth2;

  @override
  void initState() {
    super.initState();
    selectedMonth1 = '';
    selectedMonth2 = '';
    _updateSelections();
  }

  void _updateSelections() {
    final currentMonths = widget.availableMonths;
    if (currentMonths.isNotEmpty &&
        (selectedMonth1.isEmpty || !currentMonths.contains(selectedMonth1))) {
      selectedMonth1 = currentMonths[0];
    }
    if (currentMonths.length > 1 &&
        (selectedMonth2.isEmpty || !currentMonths.contains(selectedMonth2))) {
      selectedMonth2 = currentMonths[1];
    }
  }

  @override
  void didUpdateWidget(MonthCompareChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableMonths.length != widget.availableMonths.length ||
        !listEquals(oldWidget.availableMonths, widget.availableMonths)) {
      _updateSelections();
      if (mounted) {
        setState(() {});
      }
    }
  }

  int _daysInMonth(int year, int month) {
    final dt = (month < 12)
        ? DateTime(year, month + 1, 0)
        : DateTime(year + 1, 1, 0);
    return dt.day;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableMonths.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No data available for month comparison.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (widget.availableMonths.length < 2) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Center(
              child: Text(
                'Need at least two months for comparison.',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Lottie.asset('assets/lotties/chart.json', height: 250),
          ],
        ),
      );
    }

    final month1Formatted = DateFormat(
      'MMM yyyy',
    ).format(DateFormat('yyyy-MM').parse(selectedMonth1));
    final month2Formatted = DateFormat(
      'MMM yyyy',
    ).format(DateFormat('yyyy-MM').parse(selectedMonth2));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Monthly Comparison (Daily Trend)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                  ),
                  initialValue: selectedMonth1,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  dropdownColor: Colors.blue,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.blue,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: widget.availableMonths.map((month) {
                    final formatted = DateFormat(
                      'MMM yyyy',
                    ).format(DateFormat('yyyy-MM').parse(month));
                    return DropdownMenuItem(
                      value: month,
                      child: Text(
                        formatted,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMonth1 = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.black,
                  ),
                  initialValue: selectedMonth2,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  dropdownColor: Colors.amber,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.amber,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: widget.availableMonths.map((month) {
                    final formatted = DateFormat(
                      'MMM yyyy',
                    ).format(DateFormat('yyyy-MM').parse(month));
                    return DropdownMenuItem(
                      value: month,
                      child: Text(formatted),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMonth2 = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    month1Formatted,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    month2Formatted,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLineChart(month1Formatted, month2Formatted),
        ],
      ),
    );
  }

  Widget _buildLineChart(String month1Formatted, String month2Formatted) {
    if (selectedMonth1.isEmpty || selectedMonth2.isEmpty) {
      return const Center(child: Text('Select months to compare.'));
    }

    Map<int, double> month1Daily = {for (int i = 0; i < 31; i++) i: 0.0};
    Map<int, double> month2Daily = {for (int i = 0; i < 31; i++) i: 0.0};

    for (var e in widget.allExpenses) {
      final dt = DateTime.parse(e['date'] as String);
      final dayOfMonth = dt.day - 1;
      final expenseMonth = DateFormat('yyyy-MM').format(dt);

      if (expenseMonth == selectedMonth1 && dayOfMonth < 31) {
        month1Daily[dayOfMonth] =
            (month1Daily[dayOfMonth] ?? 0) + (e['amount'] as num).toDouble();
      } else if (expenseMonth == selectedMonth2 && dayOfMonth < 31) {
        month2Daily[dayOfMonth] =
            (month2Daily[dayOfMonth] ?? 0) + (e['amount'] as num).toDouble();
      }
    }

    final spots1 = List.generate(
      31,
      (i) => FlSpot(i.toDouble(), month1Daily[i] ?? 0.0),
    );
    final spots2 = List.generate(
      31,
      (i) => FlSpot(i.toDouble(), month2Daily[i] ?? 0.0),
    );

    double maxY1 = month1Daily.values.isNotEmpty
        ? month1Daily.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    double maxY2 = month2Daily.values.isNotEmpty
        ? month2Daily.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    double computedTop = [
      maxY1,
      maxY2,
      50.0,
    ].reduce((a, b) => a > b ? a : b).toDouble();
    double intervalY = (computedTop / 5).ceilToDouble();
    if (intervalY <= 0) intervalY = 1.0;

    // parse months into DateTime for tooltip date generation
    final dt1 = DateFormat('yyyy-MM').parse(selectedMonth1);
    final dt2 = DateFormat('yyyy-MM').parse(selectedMonth2);
    final daysInMonth1 = _daysInMonth(dt1.year, dt1.month);
    final daysInMonth2 = _daysInMonth(dt2.year, dt2.month);

    // Calculate totals and percent change
    final double month1Total = month1Daily.values.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final double month2Total = month2Daily.values.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final double percentChange = month2Total > 0
        ? ((month1Total - month2Total) / month2Total * 100)
        : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: computedTop + intervalY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: intervalY,
                verticalInterval: 3,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 3,
                    getTitlesWidget: (value, meta) {
                      final intDay = value.toInt();
                      final dayLabel = (intDay + 1).toString();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dayLabel,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: intervalY,
                    getTitlesWidget: (value, meta) => Text(
                      '\$${value.toInt()}',
                      style: const TextStyle(fontSize: 10),
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
                  spots: spots1,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  preventCurveOvershootingThreshold: 0,
                  isStrokeJoinRound: true,
                  isStrokeCapRound: true,
                  color: Colors.blue,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                LineChartBarData(
                  spots: spots2,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  preventCurveOvershootingThreshold: 0,
                  isStrokeJoinRound: true,
                  isStrokeCapRound: true,
                  color: Colors.amber,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.black87,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipPadding: const EdgeInsets.all(12),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((lineBarSpot) {
                      // barIndex indicates which line (0 => first, 1 => second)
                      final barIndex = lineBarSpot.barIndex;
                      final x = lineBarSpot.x.toInt().clamp(0, 30);
                      DateTime date;
                      if (barIndex == 0) {
                        final day = (x + 1).clamp(1, daysInMonth1);
                        date = DateTime(dt1.year, dt1.month, day);
                      } else {
                        final day = (x + 1).clamp(1, daysInMonth2);
                        date = DateTime(dt2.year, dt2.month, day);
                      }
                      final dateStr = DateFormat('MMM d, yyyy').format(date);
                      final y = lineBarSpot.y;
                      final color = lineBarSpot.bar.color;
                      return LineTooltipItem(
                        '$dateStr\n\$${y.toStringAsFixed(2)}',
                        TextStyle(color: color, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTrendDisplay(percentChange, month1Formatted, month2Formatted),
      ],
    );
  }

  Widget _buildTrendDisplay(
    double percentChange,
    String month1Formatted,
    String month2Formatted,
  ) {
    final isIncrease = percentChange > 0;
    final color = isIncrease ? Colors.red : Colors.green;
    final arrow = isIncrease ? '↑' : '↓';
    final changeText =
        '${percentChange.toStringAsFixed(1)}% $arrow from $month2Formatted';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIncrease ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            changeText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// -------------------- YEARLY TREND --------------------
//
// Shows 12-month totals for a chosen year (defaults to current year).
// Accepts allExpenses list where each row has 'date' (ISO string) and 'amount'.

/// YearlyTrendChart
/// - allExpenses: list of rows with at least 'date' (ISO string) and 'amount' (num)
class YearlyTrendChart extends StatefulWidget {
  final List<Map<String, dynamic>> allExpenses;
  const YearlyTrendChart({super.key, required this.allExpenses});

  @override
  State<YearlyTrendChart> createState() => _YearlyTrendChartState();
}

class _YearlyTrendChartState extends State<YearlyTrendChart> {
  late int selectedYear;
  late List<int> availableYears; // sorted descending

  @override
  void initState() {
    super.initState();
    _initYears();
  }

  void _initYears() {
    final now = DateTime.now();
    final years = <int>{};
    for (var e in widget.allExpenses) {
      try {
        final dt = DateTime.parse(e['date'] as String);
        years.add(dt.year);
      } catch (_) {}
    }
    // Always include current year even if empty
    years.add(now.year);

    availableYears = years.toList()..sort((a, b) => b.compareTo(a));
    selectedYear = now.year;
    if (availableYears.isNotEmpty && !availableYears.contains(selectedYear)) {
      selectedYear = availableYears.first;
    }
  }

  Map<int, double> _monthlyTotalsForYear(int year) {
    final totals = {for (int i = 1; i <= 12; i++) i: 0.0};
    for (var e in widget.allExpenses) {
      try {
        final dt = DateTime.parse(e['date'] as String);
        if (dt.year == year) {
          totals[dt.month] =
              (totals[dt.month] ?? 0) + (e['amount'] as num).toDouble();
        }
      } catch (_) {}
    }
    return totals;
  }

  @override
  void didUpdateWidget(YearlyTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.allExpenses, widget.allExpenses)) {
      _initYears();
      setState(() {});
    }
  }

  // A curated month color map (primary color per month).
  static const Map<int, Color> _monthPrimaryColor = {
    1: Color(0xFFB3E5FC),
    2: Color(0xFFE53935),
    3: Color(0xFF2E7D32),
    4: Color(0xFFF4F59B),
    5: Color(0xFFF6E6FF),
    6: Color(0xFFFFCC80),
    7: Color(0xFFFF8A65),
    8: Color(0xFFD84315),
    9: Color(0xFF8D6E63),
    10: Color(0xFF4B0082),
    11: Color(0xFF795548),
    12: Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    // Recompute totals each build (cheap)
    final monthlyTotals = _monthlyTotalsForYear(selectedYear);

    // Empty state handling: if selected year has no positive data -> show friendly container
    final bool hasYearData = monthlyTotals.values.any((v) => v > 0.0);

    final monthLabels = List.generate(
      12,
      (i) => DateFormat('MMM').format(DateTime(0, i + 1)),
    );

    final formatter = NumberFormat.currency(symbol: "\$");

    if (!hasYearData) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Yearly Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  iconEnabledColor: Colors.white,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  value: selectedYear,
                  items: availableYears.map((y) {
                    return DropdownMenuItem(
                      value: y,
                      child: Text(
                        y.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        selectedYear = v;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Lottie.asset("assets/lotties/list.json", height: 200),
                  Text(
                    'No expenses recorded for ${selectedYear.toString()}.',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add some expenses or choose another year to view the yearly trend.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // compute maxY and intervals
    final maxY = monthlyTotals.values.fold<double>(
      0.0,
      (p, e) => e > p ? e : p,
    );
    final computedTop = (maxY <= 0) ? 50.0 : maxY;
    final intervalY = ((computedTop / 5).ceilToDouble() <= 0)
        ? 1.0
        : (computedTop / 5).ceilToDouble();

    // Build bar groups for 12 months
    final barGroups = List.generate(12, (i) {
      final monthIndex = i + 1;
      final monthValue = monthlyTotals[monthIndex] ?? 0.0;
      final primary = _monthPrimaryColor[monthIndex] ?? Colors.blueGrey;

      // if monthValue is zero, render lighter color so user sees empties gently
      final barColor = (monthValue <= 0.0)
          ? primary.withValues(alpha: 0.25)
          : primary;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: monthValue,
            color: barColor,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            // add a subtle rod border using the accent color if there is data
            rodStackItems: [],
          ),
        ],
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header + year selector
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Yearly Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                value: selectedYear,
                items: availableYears.map((y) {
                  return DropdownMenuItem(value: y, child: Text(y.toString()));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      selectedYear = v;
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Chart area
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: computedTop + intervalY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: intervalY,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.22),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Transform.rotate(
                            angle: -pi / 3.4,
                            child: Text(
                              monthLabels[idx],
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: intervalY,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
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
                barGroups: barGroups,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final monthIdx = group.x.toInt();
                      final month = monthLabels[monthIdx];
                      final value = rod.toY;
                      return BarTooltipItem(
                        '$month\n${formatter.format(value)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${selectedYear.toString()})',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Text(
                formatter.format(
                  monthlyTotals.values.fold(0.0, (p, e) => p + e),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------- CATEGORY PIE CHART --------------------
class CategoryPieChart extends StatelessWidget {
  final Map<String, Map<String, dynamic>> categoryExpenses;
  const CategoryPieChart({super.key, required this.categoryExpenses});

  @override
  Widget build(BuildContext context) {
    if (categoryExpenses.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No category data to show.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final total = categoryExpenses.values
        .map((m) => (m['amount'] as num).toDouble())
        .fold<double>(0.0, (p, e) => p + e);

    final sections = <PieChartSectionData>[];
    categoryExpenses.forEach((name, m) {
      final amount = (m['amount'] as num).toDouble();
      final color = (m['color'] is Color) ? m['color'] as Color : Colors.grey;
      final percent = total > 0 ? amount / total : 0.0;

      sections.add(
        PieChartSectionData(
          value: amount,
          title: '${(percent * 100).toStringAsFixed(0)}%',
          color: color,
          radius: 36,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: null,
          showTitle: percent >= 0.06, // avoid tiny labels crowding
        ),
      );
    });

    // Legend builder
    Widget buildLegend() {
      final items = categoryExpenses.entries.toList();
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: items.take(8).map((e) {
          final name = e.key;
          final amount = (e.value['amount'] as num).toDouble();
          final color = (e.value['color'] is Color)
              ? e.value['color'] as Color
              : Colors.grey;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$name • \$${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }).toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 34,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          // no state needed here; tooltip handled by library if used externally
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(child: buildLegend()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: \$${total.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// -------------------- WEEKDAY BAR CHART --------------------
class WeekdayBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> last30DaysExpenses;
  const WeekdayBarChart({super.key, required this.last30DaysExpenses});

  @override
  Widget build(BuildContext context) {
    if (last30DaysExpenses.isEmpty) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text(
                'No data available for weekday breakdown.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    // Aggregate totals by weekday (Mon=1 ... Sun=7)
    final Map<int, double> weekdayTotals = {
      for (int i = 1; i <= 7; i++) i: 0.0,
    };
    for (var e in last30DaysExpenses) {
      final dt = e['date'] as DateTime;
      final wd = dt.weekday;
      weekdayTotals[wd] =
          (weekdayTotals[wd] ?? 0) + (e['amount'] as num).toDouble();
    }

    // Prepare bar groups (0..6)
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = weekdayTotals.values.fold<double>(
      0.0,
      (p, e) => e > p ? e : p,
    );
    final computedTop = (maxY <= 0) ? 50.0 : maxY;
    final intervalY = ((computedTop / 4).ceilToDouble() <= 0)
        ? 1.0
        : (computedTop / 4).ceilToDouble();

    final groups = List.generate(7, (i) {
      final val = weekdayTotals[i + 1] ?? 0.0;
      final color = (val <= 0)
          ? Colors.grey.withValues(alpha: 0.25)
          : Colors.deepPurpleAccent;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            color: color,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Spending by Weekday',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: computedTop + intervalY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: intervalY,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: intervalY,
                      getTitlesWidget: (v, meta) => Text(
                        '\$${v.toInt()}',
                        style: const TextStyle(fontSize: 10),
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
                barGroups: groups,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = labels[group.x.toInt()];
                      return BarTooltipItem(
                        '$label\n\$${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- CUMULATIVE AREA (LAST 30 DAYS) --------------------
class CumulativeAreaChart extends StatelessWidget {
  final List<Map<String, dynamic>> last30DaysExpenses;
  const CumulativeAreaChart({super.key, required this.last30DaysExpenses});

  @override
  Widget build(BuildContext context) {
    if (last30DaysExpenses.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No data for cumulative chart.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Build daily totals (30 days) same indexing as Last30DaysChart
    Map<int, double> dailyTotals = {for (int i = 0; i < 30; i++) i: 0.0};
    final now = DateTime.now();
    for (var e in last30DaysExpenses) {
      DateTime dt = e['date'] as DateTime;
      int diff = now.difference(dt).inDays;
      if (diff < 30 && diff >= 0) {
        dailyTotals[29 - diff] =
            (dailyTotals[29 - diff] ?? 0) + (e['amount'] as num).toDouble();
      }
    }

    // cumulative
    double running = 0.0;
    final spots = List.generate(30, (i) {
      running += dailyTotals[i] ?? 0.0;
      return FlSpot(i.toDouble(), running);
    });

    final maxY = spots
        .map((s) => s.y)
        .fold<double>(0.0, (p, e) => e > p ? e : p);
    final computedTop = (maxY <= 0) ? 50.0 : maxY;
    final intervalY = ((computedTop / 5).ceilToDouble() <= 0)
        ? 1.0
        : (computedTop / 5).ceilToDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Cumulative Expenses (30 days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: computedTop + intervalY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: intervalY,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt().clamp(0, 29);
                        final daysAgo = 29 - idx;
                        final date = now.subtract(Duration(days: daysAgo));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: intervalY,
                      getTitlesWidget: (v, meta) => Text(
                        '\$${v.toInt()}',
                        style: const TextStyle(fontSize: 10),
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
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.green,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.45),
                          Colors.green.withValues(alpha: 0.12),
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
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((t) {
                        final idx = t.x.toInt().clamp(0, 29);
                        final daysAgo = 29 - idx;
                        final date = DateTime.now().subtract(
                          Duration(days: daysAgo),
                        );
                        final dateStr = DateFormat('MMM d').format(date);
                        return LineTooltipItem(
                          '$dateStr\n\$${t.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current cumulative (30D): \$${spots.last.y.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// -------------------- TOP EXPENSES LIST (with mini sparklines) --------------------
class TopExpensesList extends StatelessWidget {
  final List<Map<String, dynamic>> allExpenses;
  final int topN;
  final Map<String, Color> categoryColors;
  const TopExpensesList({
    super.key,
    required this.allExpenses,
    this.topN = 5,
    this.categoryColors = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (allExpenses.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No expenses recorded yet.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // sort descending by amount and take topN
    final sorted = List<Map<String, dynamic>>.from(allExpenses)
      ..sort((a, b) => (b['amount'] as num).compareTo(a['amount'] as num));
    final top = sorted.take(topN).toList();

    Widget miniSparklineFor(Map<String, dynamic> entry) {
      // Build a tiny sparkline from surrounding days of this entry (if available)
      final dt = DateTime.parse(entry['date'] as String);
      final start = dt.subtract(const Duration(days: 6));
      final Map<int, double> byDay = {for (int i = 0; i < 7; i++) i: 0.0};
      for (var e in allExpenses) {
        final d = DateTime.parse(e['date'] as String);
        if (!d.isBefore(start) && !d.isAfter(dt)) {
          final idx = d.difference(start).inDays;
          if (idx >= 0 && idx < 7) {
            byDay[idx] = (byDay[idx] ?? 0) + (e['amount'] as num).toDouble();
          }
        }
      }
      final spots = List.generate(
        7,
        (i) => FlSpot(i.toDouble(), byDay[i] ?? 0.0),
      );
      final maxY =
          spots.map((s) => s.y).fold<double>(0.0, (p, e) => e > p ? e : p) +
          1.0;
      return SizedBox(
        width: 90,
        height: 34,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.deepPurpleAccent,
                dotData: const FlDotData(show: false),
                barWidth: 2,
              ),
            ],
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: top.map((e) {
              final amount = (e['amount'] as num).toDouble();
              final date = DateTime.parse(e['date'] as String);
              final cat = e['category'] as String? ?? 'Uncategorized';
              // look up category color from provided map, fallback to a neutral color
              final displayColor =
                  categoryColors[cat] ??
                  (e['color'] is int ? Color(e['color'] as int) : Colors.grey);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 36,
                      decoration: BoxDecoration(
                        color: displayColor.withValues(alpha: 1.0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        miniSparklineFor(e),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

