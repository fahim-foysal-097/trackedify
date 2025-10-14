import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:trackedify/database/database_helper.dart';

// TODO : improve cards style

class MonthlyOverviewTab extends StatefulWidget {
  const MonthlyOverviewTab({super.key});

  @override
  State<MonthlyOverviewTab> createState() => MonthlyOverviewTabState();
}

class MonthlyOverviewTabState extends State<MonthlyOverviewTab> {
  List<Map<String, dynamic>> monthlyData = [];
  Map<String, List<Map<String, dynamic>>> groupedByMonth = {};
  String? selectedMonth; // yyyy-MM
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMonthlyData();
  }

  Future<void> loadMonthlyData() async {
    setState(() => isLoading = true);
    final db = await DatabaseHelper().database;
    final allExpenses = await db.query('expenses', orderBy: 'date DESC');

    // Group expenses by month-year
    groupedByMonth = {};
    for (var exp in allExpenses) {
      final date = DateTime.parse(exp['date'] as String);
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      groupedByMonth.putIfAbsent(monthKey, () => []).add(exp);
    }

    // Prepare monthly summary with top 3 categories
    List<Map<String, dynamic>> summary = [];
    groupedByMonth.forEach((month, expenses) {
      Map<String, double> categoryTotals = {};
      double monthTotal = 0;
      for (var exp in expenses) {
        final amount = (exp['amount'] as num).toDouble();
        monthTotal += amount;
        categoryTotals.update(
          exp['category'],
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }

      final topCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      summary.add({
        'month': month,
        'total': monthTotal,
        'topCategories': topCategories.take(3).toList(),
      });
    });

    // sort months descending (newest first)
    summary.sort(
      (a, b) => (b['month'] as String).compareTo(a['month'] as String),
    );

    // Build full available months list: include current month even if empty,
    // so user can view the current month immediately.
    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    final availableMonths = <String>{
      ...groupedByMonth.keys, // months that have data
      currentMonthKey, // always include current month
    }.toList()..sort((a, b) => b.compareTo(a)); // newest-first

    // initialize selectedMonth to current month (preferred) otherwise first available
    final initSelected = availableMonths.contains(currentMonthKey)
        ? currentMonthKey
        : (availableMonths.isNotEmpty ? availableMonths.first : null);

    if (mounted) {
      setState(() {
        monthlyData = summary;
        selectedMonth = initSelected;
        isLoading = false;
      });
    }
  }

  String formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateFormat('MMMM yyyy').format(DateTime(year, month));
  }

  /// Returns map day -> total for given yyyy-MM
  Map<int, double> dailyTotalsForMonth(String ym) {
    final parts = ym.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final Map<int, double> ret = {
      for (var i = 1; i <= daysInMonth; i++) i: 0.0,
    };

    final rows = groupedByMonth[ym];
    if (rows != null) {
      for (var r in rows) {
        final dt = DateTime.parse(r['date'] as String);
        final day = dt.day;
        if (day >= 1 && day <= daysInMonth) {
          ret[day] = (ret[day] ?? 0) + (r['amount'] as num).toDouble();
        }
      }
    }

    // ensure non-negative and finite
    ret.updateAll((k, v) {
      if (v.isNaN || v.isInfinite) return 0.0;
      return v < 0 ? 0.0 : v;
    });

    return ret;
  }

  Widget _buildChartCard() {
    if (selectedMonth == null) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    final totals = dailyTotalsForMonth(selectedMonth!);
    final daysInMonth = totals.length;
    final allZero = totals.values.every((v) => v == 0.0);

    // Build available months list (newest first) — include current month even if no expenses
    final nowKey = DateFormat('yyyy-MM').format(DateTime.now());
    final availableMonths = <String>{...groupedByMonth.keys, nowKey}.toList()
      ..sort((a, b) => b.compareTo(a));

    // ensure selectedMonth has a sensible default
    selectedMonth ??= availableMonths.contains(nowKey)
        ? nowKey
        : (availableMonths.isNotEmpty ? availableMonths.first : nowKey);

    // If month has no data -> show friendly empty card (keeps dropdown above)
    if (allZero) {
      return Card(
        color: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedMonth,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: availableMonths.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(formatMonth(m)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        selectedMonth = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loadMonthlyData,
                  icon: Icon(Icons.refresh, color: cs.primary),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18.0),
                  child: Text(
                    'No expenses recorded for this month yet.',
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // build spots (x: day 1..daysInMonth)
    final spots = <FlSpot>[
      FlSpot(0, totals[1] ?? 0.0), // anchor point at x=0
      ...List<FlSpot>.generate(
        daysInMonth,
        (i) => FlSpot((i + 1).toDouble(), totals[i + 1] ?? 0.0),
      ),
    ];

    // compute maxY
    double maxY = totals.values.isNotEmpty
        ? totals.values.reduce((a, b) => a > b ? a : b)
        : 10.0;
    double computedTop = (maxY <= 0) ? 10.0 : (maxY * 1.2);
    double intervalY = (computedTop / 4);
    if (intervalY <= 0) intervalY = 1.0;

    return Card(
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedMonth,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: availableMonths.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(formatMonth(m)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        selectedMonth = v;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: loadMonthlyData,
                  icon: Icon(Icons.refresh, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: daysInMonth.toDouble(),
                  minY: 0,
                  maxY: computedTop,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: intervalY,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (daysInMonth / 10).clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final intVal = value.toInt();
                          if (intVal < 1 || intVal > daysInMonth) {
                            return const SizedBox();
                          }
                          // show day numbers sparsely
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              intVal.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: intervalY,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: TextStyle(fontSize: 10, color: cs.onSurface),
                          );
                        },
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
                      barWidth: 3,
                      color: cs.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            cs.primary.withValues(alpha: 0.5),
                            cs.primary.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          cs.onSurface.withValues(alpha: 0.9),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((t) {
                          final day = t.x.toInt();
                          final value = t.y;
                          return LineTooltipItem(
                            'Day $day\n\$${value.toStringAsFixed(2)}',
                            TextStyle(color: cs.onPrimary, fontSize: 12),
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

  Widget _buildMonthCard(Map<String, dynamic> monthInfo) {
    final cs = Theme.of(context).colorScheme;
    final total = (monthInfo['total'] as num).toDouble();
    final month = monthInfo['month'] as String;
    final topCats = monthInfo['topCategories'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.primaryContainer.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header with icon
            Row(
              children: [
                Icon(Icons.calendar_today, color: cs.onPrimary, size: 24),
                const SizedBox(width: 8),
                Text(
                  formatMonth(month),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total with icon
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: cs.onPrimary.withValues(alpha: 0.9),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18,
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Categories header
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: cs.onPrimary.withValues(alpha: 0.9),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  "Top 3 Categories",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: cs.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...topCats.map<Widget>((catEntry) {
              // catEntry is MapEntry<String,double>
              final category = catEntry.key.toString();
              final value = (catEntry.value as num).toDouble();
              final percent = total > 0 ? (value / total) : 0.0;

              final progressColor = percent * 100 <= 50
                  ? cs.onPrimary
                  : cs.onPrimary;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            "\$${value.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: cs.onPrimary.withValues(
                                  alpha: 0.12,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${(percent * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (isLoading) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: (MediaQuery.of(context).size.height / 2) - 200),
            CupertinoActivityIndicator(radius: 12, color: cs.primary),
          ],
        ),
      );
    }

    final hasAnyData = monthlyData.isNotEmpty || groupedByMonth.isNotEmpty;
    if (!hasAnyData) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 2),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No monthly expenses to show',
                  style: TextStyle(
                    fontSize: 16,
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please add some expenses.',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(right: 6, left: 6),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Chart area for selected month
          _buildChartCard(),

          const SizedBox(height: 12),

          // Monthly cards list (summary for each month we have records for)
          ListView.builder(
            itemCount: monthlyData.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final monthInfo = monthlyData[index];
              return _buildMonthCard(monthInfo);
            },
          ),
        ],
      ),
    );
  }
}
