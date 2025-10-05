import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:intl/intl.dart';

class MyPieChart extends StatefulWidget {
  const MyPieChart({super.key});

  @override
  State<MyPieChart> createState() => MyPieChartState();
}

class MyPieChartState extends State<MyPieChart> {
  Map<String, Map<String, dynamic>> categoryMap = {}; // name -> {color, icon}
  Map<String, double> categoryTotals = {};
  Map<String, int> categoryCounts = {};
  int? touchedIndex;

  // Additional stats
  int totalTransactions = 0;
  double largestSingleExpense = 0.0;
  String? largestExpenseCategory;
  double totalThisMonth = 0.0;
  double totalLastMonth = 0.0;
  Map<String, int> dayOfWeekCounts = {};
  Set<String> uniqueDates = <String>{};
  double smallestExpense = double.infinity;
  String? smallestExpenseCategory;
  String? mostActiveDay;
  int mostActiveDayCount = 0;
  double avgDailySpend = 0.0;
  double trendPercentage = 0.0;
  IconData trendIcon = Icons.trending_flat;
  Color trendColor = Colors.grey;
  String trendText = 'Stable';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategoriesAndExpenses();
  }

  Future<void> loadCategoriesAndExpenses() async {
    setState(() => isLoading = true);

    final db = await DatabaseHelper().database;

    // Load categories
    final dbCategories = await db.query('categories');
    categoryMap = {
      for (var cat in dbCategories)
        (cat['name'] as String): {
          'color': Color(cat['color'] as int),
          'icon': IconData(
            cat['icon_code'] as int,
            fontFamily: 'MaterialIcons',
          ),
        },
    };

    // Load expenses
    final data = await db.query('expenses');

    final Map<String, double> totals = {};
    final Map<String, int> counts = {};
    int txCount = 0;
    double maxExpense = 0.0;
    String? maxExpenseCat;
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;
    int lastMonthNum = currentMonth - 1;
    int lastYear = currentYear;
    if (lastMonthNum == 0) {
      lastMonthNum = 12;
      lastYear--;
    }
    double totalThis = 0.0;
    double totalLast = 0.0;
    Map<String, int> dowCounts = {};
    Set<String> uDates = <String>{};
    double minExpense = double.infinity;
    String? minExpenseCat;

    for (var row in data) {
      final categoryName = row['category'] as String;
      final amount = (row['amount'] as num).toDouble();

      totals[categoryName] = (totals[categoryName] ?? 0) + amount;
      counts[categoryName] = (counts[categoryName] ?? 0) + 1;

      txCount += 1;
      if (amount > maxExpense) {
        maxExpense = amount;
        maxExpenseCat = categoryName;
      }
      if (amount < minExpense) {
        minExpense = amount;
        minExpenseCat = categoryName;
      }

      final expenseDateStr = row['date'] as String;
      final expenseDate = DateTime.parse(expenseDateStr);
      final dow = DateFormat('EEEE').format(expenseDate);
      dowCounts[dow] = (dowCounts[dow] ?? 0) + 1;
      final dateKey = expenseDate.toIso8601String().split('T')[0];
      uDates.add(dateKey);

      if (expenseDate.month == currentMonth &&
          expenseDate.year == currentYear) {
        totalThis += amount;
      }
      if (expenseDate.month == lastMonthNum && expenseDate.year == lastYear) {
        totalLast += amount;
      }
    }

    int numUniqueDays = uDates.length;
    double avgDaily = numUniqueDays > 0
        ? (totals.values.fold<double>(0, (s, v) => s + v) / numUniqueDays)
        : 0.0;

    String? mActiveDay;
    int mActiveCount = 0;
    if (dowCounts.isNotEmpty) {
      final maxEntry = dowCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mActiveDay = maxEntry.key;
      mActiveCount = maxEntry.value;
    } else {
      mActiveDay = 'None';
      mActiveCount = 0;
    }

    double trendPct = totalLast > 0
        ? ((totalThis - totalLast) / totalLast * 100)
        : 0;
    String tText = totalThis > totalLast
        ? 'Up ${trendPct.toStringAsFixed(0)}%'
        : (totalThis < totalLast
              ? 'Down ${(-trendPct).toStringAsFixed(0)}%'
              : 'Stable');
    IconData tIcon = totalThis > totalLast
        ? Icons.trending_up
        : (totalThis < totalLast ? Icons.trending_down : Icons.trending_flat);
    Color tColor = totalThis > totalLast
        ? Colors.green
        : (totalThis < totalLast ? Colors.red : Colors.grey);

    if (minExpense == double.infinity) {
      minExpense = 0.0;
      minExpenseCat = 'None';
    }

    if (mounted) {
      setState(() {
        categoryTotals = totals;
        categoryCounts = counts;
        totalTransactions = txCount;
        largestSingleExpense = maxExpense;
        largestExpenseCategory = maxExpenseCat;
        totalThisMonth = totalThis;
        totalLastMonth = totalLast;
        dayOfWeekCounts = dowCounts;
        uniqueDates = uDates;
        smallestExpense = minExpense;
        smallestExpenseCategory = minExpenseCat;
        mostActiveDay = mActiveDay;
        mostActiveDayCount = mActiveCount;
        avgDailySpend = avgDaily;
        trendPercentage = trendPct;
        trendIcon = tIcon;
        trendColor = tColor;
        trendText = tText;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 2),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No data for pie chart',
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

    final entries = categoryTotals.entries.toList();
    final totalExpense = entries.fold<double>(0.0, (s, e) => s + e.value);
    final totalTx = totalTransactions == 0 ? 1 : totalTransactions;
    final averageExpense = totalExpense / totalTx;

    // Top by count
    final sortedByCount = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topByCount = sortedByCount.take(3).toList();
    String mostFreqCat = topByCount.isNotEmpty ? topByCount.first.key : 'None';
    int freqCount = topByCount.isNotEmpty ? topByCount.first.value : 0;

    // Top by spend
    final sortedBySpend = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    String? topCategory = sortedBySpend.isNotEmpty
        ? sortedBySpend.first.key
        : null;
    double topAmount = sortedBySpend.isNotEmpty ? sortedBySpend.first.value : 0;
    double topPercentage = totalExpense > 0
        ? (topAmount / totalExpense * 100)
        : 0;

    // sizing constants
    const chartHeight = 320.0;
    const baseRadius = 78.0;
    const touchedRadius = 95.0;
    const centerSpaceRadius = 52.0; // empty center size

    final sections = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value; // MapEntry<String, double>
      final cat =
          categoryMap[data.key] ??
          {'color': Colors.grey, 'icon': Icons.category};

      final isTouched = index == touchedIndex;

      return PieChartSectionData(
        color: cat['color'] as Color,
        value: data.value,
        radius: isTouched ? touchedRadius : baseRadius,
        title: isTouched ? '\$${data.value.toStringAsFixed(2)}' : '',
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        borderSide: isTouched
            ? BorderSide(color: Colors.black.withValues(alpha: 0.12), width: 2)
            : BorderSide.none,
      );
    }).toList();

    // Stat cards
    List<Widget> statCards = [
      _buildStatCard(
        icon: Icons.numbers,
        title: 'Total Spent',
        value: '\$${totalExpense.toStringAsFixed(2)}',
        color: Colors.green,
      ),
      _buildStatCard(
        icon: Icons.receipt_long,
        title: 'Transactions',
        value: totalTransactions.toString(),
        color: Colors.blue,
      ),
      _buildStatCard(
        icon: Icons.trending_up,
        title: 'Avg per Tx',
        value: '\$${averageExpense.toStringAsFixed(2)}',
        color: Colors.orange,
      ),
      _buildStatCard(
        icon: Icons.calendar_today,
        title: 'This Month',
        value: '\$${totalThisMonth.toStringAsFixed(2)}',
        color: Colors.purple,
      ),
      _buildStatCard(
        icon: Icons.date_range,
        title: 'Avg Daily',
        value: '\$${avgDailySpend.toStringAsFixed(2)}',
        color: Colors.cyan,
      ),
      _buildStatCard(
        icon: Icons.warning_rounded,
        title: 'Largest',
        value: largestExpenseCategory ?? 'None',
        subValue: '\$${largestSingleExpense.toStringAsFixed(2)}',
        color: Colors.red,
      ),
      _buildStatCard(
        icon: Icons.savings,
        title: 'Smallest',
        value: smallestExpenseCategory ?? 'None',
        subValue: '\$${smallestExpense.toStringAsFixed(2)}',
        color: Colors.lightGreen,
      ),
      _buildStatCard(
        icon: Icons.event,
        title: 'Busiest Day',
        value: '$mostActiveDay',
        subValue: '($mostActiveDayCount tx)',
        color: Colors.indigo,
      ),
      _buildStatCard(
        icon: trendIcon,
        title: 'Monthly Trend',
        value: trendText,
        color: trendColor,
      ),
      _buildStatCard(
        icon: Icons.tag,
        title: 'Top Category',
        value: topCategory ?? 'None',
        subValue:
            '\$${topAmount.toStringAsFixed(2)} (${topPercentage.toStringAsFixed(0)}%)',
        color: Colors.teal,
      ),
      _buildStatCard(
        icon: Icons.cached_rounded,
        title: 'Most Frequent',
        value: mostFreqCat,
        subValue: '$freqCount tx',
        color: Colors.amber,
      ),
      _buildStatCard(
        icon: Icons.layers,
        title: 'Unique Categories',
        value: categoryTotals.length.toString(),
        color: Colors.pink,
      ),
    ];

    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    } else {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Expenses by Category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            // Pie chart area (fixed height to avoid unbounded height)
            SizedBox(
              height: chartHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 4,
                      startDegreeOffset: -90,
                      centerSpaceRadius: centerSpaceRadius,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (response != null &&
                                response.touchedSection != null &&
                                event is! PointerExitEvent &&
                                event is! PointerUpEvent) {
                              touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            } else {
                              touchedIndex = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  // Center overlay showing total expense
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Legend: wrap so it uses available width and doesn't force height
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final cat =
                      categoryMap[data.key] ??
                      {'color': Colors.grey, 'icon': Icons.category};
                  final isSelected = touchedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        touchedIndex = isSelected ? null : index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.amberAccent.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(width: 2, color: Colors.black26)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${data.key} (\$${data.value.toStringAsFixed(2)})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Insights cards grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Quick Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
        padding: const EdgeInsets.all(12),
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
