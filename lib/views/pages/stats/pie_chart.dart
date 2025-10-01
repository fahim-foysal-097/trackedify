import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendle/database/database_helper.dart';

class MyPieChart extends StatefulWidget {
  const MyPieChart({super.key});

  @override
  State<MyPieChart> createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  Map<String, Map<String, dynamic>> categoryMap = {}; // name -> {color, icon}
  Map<String, double> categoryTotals = {};
  Map<String, int> categoryCounts = {};
  int? touchedIndex;

  // Additional stats
  int totalTransactions = 0;
  double largestSingleExpense = 0.0;
  String? largestExpenseCategory;

  @override
  void initState() {
    super.initState();
    loadCategoriesAndExpenses();
  }

  Future<void> loadCategoriesAndExpenses() async {
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
    }

    if (mounted) {
      setState(() {
        categoryTotals = totals;
        categoryCounts = counts;
        totalTransactions = txCount;
        largestSingleExpense = maxExpense;
        largestExpenseCategory = maxExpenseCat;
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
            ? const BorderSide(color: Colors.black38, width: 2)
            : BorderSide.none,
      );
    }).toList();

    // --- Insights computation ---

    final sortedByCount = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topByCount = sortedByCount.take(3).toList();

    final largeShareCategories =
        categoryTotals.entries
            .where(
              (e) => totalExpense > 0 ? e.value / totalExpense >= 0.20 : false,
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Make the whole widget scrollable if the content is tall (fixes overflow).
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        fontSize: 18,
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
          Wrap(
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
                        ? Colors.grey.shade100
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
                          color: isSelected ? Colors.black87 : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Insights cards (these can be long; let them flow inside the SingleChildScrollView)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insights',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 8),

                _buildInsightCard(
                  title: 'Most frequent categories (by transactions)',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topByCount.map((e) {
                      final totalForCat = categoryTotals[e.key] ?? 0.0;
                      final avgPerTx = e.value == 0
                          ? 0.0
                          : totalForCat / e.value;
                      final cat = categoryMap[e.key];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: (cat != null
                              ? cat['color'] as Color
                              : Colors.grey),
                          child: Icon(
                            cat != null
                                ? cat['icon'] as IconData
                                : Icons.category,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          e.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${e.value} transactions • avg \$${avgPerTx.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '\$${totalForCat.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                _buildInsightCard(
                  title: 'Quick stats',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _smallStatColumn('Transactions', '$totalTx'),
                      _smallStatColumn(
                        'Avg per tx',
                        '\$${averageExpense.toStringAsFixed(2)}',
                      ),
                      _smallStatColumn(
                        'Largest',
                        '\$${largestSingleExpense.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (largeShareCategories.isNotEmpty)
                  _buildInsightCard(
                    title: 'Big contributors (≥ 20% of total)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: largeShareCategories.map((e) {
                        final pct = totalExpense > 0
                            ? (e.value / totalExpense) * 100
                            : 0.0;
                        final cat = categoryMap[e.key];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: (cat != null
                                    ? cat['color'] as Color
                                    : Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${e.key} — \$${e.value.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text('${pct.toStringAsFixed(1)}%'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  _buildInsightCard(
                    title: 'Big contributors (≥ 20% of total)',
                    child: const Text(
                      'No single category takes 20% or more of total spending.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Small reusable card for insights
  Widget _buildInsightCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }

  Widget _smallStatColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
