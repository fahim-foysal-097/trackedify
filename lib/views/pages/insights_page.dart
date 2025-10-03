import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:spendle/database/database_helper.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => InsightsPageState();
}

class InsightsPageState extends State<InsightsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  double totalExpense = 0;
  Map<String, Map<String, dynamic>> categoryExpenses = {};
  List<Map<String, dynamic>> last30DaysExpenses = [];
  List<Map<String, dynamic>> last7DaysExpenses = [];
  Map<String, dynamic> insightsData = {};
  List<String> availableMonths = []; // 'yyyy-MM' strings
  List<Map<String, dynamic>> allExpenses = [];

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  void refresh() {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> all = await db.query(
      'expenses',
      orderBy: 'date ASC',
    );

    // store all expenses locally for the month-compare widget to query
    allExpenses = all;

    double total = 0;
    Map<String, Map<String, dynamic>> catMap = {};
    List<Map<String, dynamic>> last30 = [];
    List<Map<String, dynamic>> last7 = [];
    final now = DateTime.now();

    double maxExpense = 0;
    double minExpense = double.infinity;
    Map<String, int> freqCategory = {};
    Map<String, double> monthlyTotals = {};

    // fetch categories for colors
    final categories = await db.query('categories');
    Map<String, Color> categoryColors = {};
    for (var c in categories) {
      categoryColors[c['name'] as String] = Color(
        c['color'] as int,
      ).withValues(alpha: 1.0);
    }

    for (var e in all) {
      final amt = (e['amount'] as num).toDouble();
      final cat = e['category'] as String;
      final dt = DateTime.parse(e['date'] as String);

      total += amt;
      if (catMap.containsKey(cat)) {
        catMap[cat]!['amount'] += amt;
      } else {
        catMap[cat] = {
          'amount': amt,
          'color': categoryColors[cat] ?? Colors.grey,
        };
      }

      final ym = DateFormat('yyyy-MM').format(dt);
      monthlyTotals[ym] = (monthlyTotals[ym] ?? 0) + amt;

      if (amt > maxExpense) maxExpense = amt;
      if (amt < minExpense) minExpense = amt;

      freqCategory[cat] = (freqCategory[cat] ?? 0) + 1;

      if (dt.isAfter(now.subtract(const Duration(days: 30)))) {
        last30.add({'date': dt, 'amount': amt});
      }
      if (dt.isAfter(now.subtract(const Duration(days: 7)))) {
        last7.add({'date': dt, 'amount': amt});
      }
    }

    // Sort categories by amount descending for top categories
    final sortedCategories = catMap.entries.toList()
      ..sort(
        (a, b) =>
            (b.value['amount'] as num).compareTo(a.value['amount'] as num),
      );
    final topCategories = Map.fromEntries(sortedCategories.take(7));

    // Weekly average (last 7 days)
    double weeklyTotal = last7.fold(
      0.0,
      (p, e) => p + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
    double weeklyAvg = last7.isNotEmpty ? weeklyTotal / last7.length : 0;

    String mostFreqCategory = freqCategory.isEmpty
        ? "N/A"
        : freqCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Build month list from allExpenses (for dropdowns & comparison)
    final monthSet = <String>{};
    for (var e in all) {
      final dt = DateTime.parse(e['date'] as String);
      monthSet.add(DateFormat('yyyy-MM').format(dt));
    }
    final months = monthSet.toList();
    months.sort((a, b) => b.compareTo(a)); // newest first

    // -------------------------
    // TREND CALC (calendar months)
    // -------------------------
    final thisYm = DateFormat('yyyy-MM').format(now);
    final prevYm = DateFormat(
      'yyyy-MM',
    ).format(DateTime(now.year, now.month - 1));

    final double currentMonth = (monthlyTotals[thisYm] ?? 0.0);
    final double prevMonth = (monthlyTotals[prevYm] ?? 0.0);

    double percentChange;
    if (prevMonth > 0) {
      percentChange = ((currentMonth - prevMonth) / prevMonth) * 100.0;
    } else if (prevMonth == 0 && currentMonth == 0) {
      percentChange = 0.0;
    } else {
      // prev == 0 && currentMonth > 0
      percentChange = 100.0;
    }

    setState(() {
      totalExpense = total;
      categoryExpenses = topCategories;
      last30DaysExpenses = last30;
      last7DaysExpenses = last7;
      insightsData = {
        'maxExpense': maxExpense,
        'minExpense': minExpense == double.infinity ? 0 : minExpense,
        'mostFreqCategory': mostFreqCategory,
        'weeklyAvg': weeklyAvg,
        'currentMonth': currentMonth,
        'previousMonth': prevMonth,
        'percentChange': percentChange,
      };
      availableMonths = months;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Insights",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ExpenseSummaryCard(totalExpense: totalExpense),
              const SizedBox(height: 16),
              InsightsCards(insights: insightsData),
              const SizedBox(height: 20),
              ExpenseLineChart(last30DaysExpenses: last30DaysExpenses),
              const SizedBox(height: 20),
              MonthCompareChart(
                allExpenses: allExpenses,
                availableMonths: availableMonths,
              ),
              const SizedBox(height: 20),
              YearlyTrendChart(allExpenses: allExpenses),
              const SizedBox(height: 20),
              ExpenseBarChart(categoryExpenses: categoryExpenses),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- EXPENSE SUMMARY & INSIGHTS --------------------

class ExpenseSummaryCard extends StatelessWidget {
  final double totalExpense;
  const ExpenseSummaryCard({super.key, required this.totalExpense});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: "\$");
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.lightBlueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Expense",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                formatter.format(totalExpense),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Icon(Icons.pie_chart, color: Colors.white, size: 36),
        ],
      ),
    );
  }
}

class InsightsCards extends StatelessWidget {
  final Map<String, dynamic> insights;
  const InsightsCards({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: "\$");

    double safeDouble(Object? o) => (o as num?)?.toDouble() ?? 0.0;

    final percent = safeDouble(insights['percentChange']);
    final percentLabel = percent.isFinite
        ? '${percent.toStringAsFixed(1)}%'
        : '—';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildCard(
                title: "Max Expense",
                value: safeDouble(insights['maxExpense']),
                color: Colors.red,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Min Expense",
                value: safeDouble(insights['minExpense']),
                color: Colors.green,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Most Frequent",
                valueText: insights['mostFreqCategory'] ?? "N/A",
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildCard(
                title: "Weekly Avg",
                value: safeDouble(insights['weeklyAvg']),
                color: Colors.purple,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Current Month",
                value: safeDouble(insights['currentMonth']),
                color: Colors.blue,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Trend",
                valueText: percentLabel,
                // color: red when spending increased vs previous month (bad), green when decreased (good)
                color: percent >= 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    double? value,
    String? valueText,
    required Color color,
    NumberFormat? formatter,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value != null ? formatter!.format(value) : valueText ?? "",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// -------------------- EXPENSE LINE CHART --------------------

class ExpenseLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> last30DaysExpenses;
  const ExpenseLineChart({super.key, required this.last30DaysExpenses});

  @override
  Widget build(BuildContext context) {
    if (last30DaysExpenses.isEmpty) {
      return Card(
        color: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data available for last 30 days chart.',
              style: TextStyle(color: Colors.white),
            ),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
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
                      dotData: const FlDotData(show: false), // ? show dots
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
          ],
        ),
      ),
    );
  }
}

// -------------------- EXPENSE BAR CHART --------------------

class ExpenseBarChart extends StatelessWidget {
  final Map<String, Map<String, dynamic>> categoryExpenses;
  const ExpenseBarChart({super.key, required this.categoryExpenses});

  @override
  Widget build(BuildContext context) {
    if (categoryExpenses.isEmpty) {
      return Card(
        color: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data available for categories.',
              style: TextStyle(color: Colors.white),
            ),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
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
      return Card(
        color: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No data available for month comparison.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (widget.availableMonths.length < 2) {
      return Card(
        color: Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        child: Padding(
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
        ),
      );
    }

    final month1Formatted = DateFormat(
      'MMM yyyy',
    ).format(DateFormat('yyyy-MM').parse(selectedMonth1));
    final month2Formatted = DateFormat(
      'MMM yyyy',
    ).format(DateFormat('yyyy-MM').parse(selectedMonth2));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Comparison (Daily Trend)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

    // Empty state handling: if selected year has no positive data -> show friendly card
    final bool hasYearData = monthlyTotals.values.any((v) => v > 0.0);

    final monthLabels = List.generate(
      12,
      (i) => DateFormat('MMM').format(DateTime(0, i + 1)),
    );

    final formatter = NumberFormat.currency(symbol: "\$");

    if (!hasYearData) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.red,
        elevation: 6,
        child: Padding(
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Padding(
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
                    return DropdownMenuItem(
                      value: y,
                      child: Text(y.toString()),
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
      ),
    );
  }
}
