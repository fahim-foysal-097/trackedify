import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';

class MonthlyOverviewTab extends StatefulWidget {
  const MonthlyOverviewTab({super.key});

  @override
  State<MonthlyOverviewTab> createState() => _MonthlyOverviewTabState();
}

class _MonthlyOverviewTabState extends State<MonthlyOverviewTab> {
  List<Map<String, dynamic>> monthlyData = [];

  @override
  void initState() {
    super.initState();
    loadMonthlyData();
  }

  Future<void> loadMonthlyData() async {
    final db = await DatabaseHelper().database;
    final allExpenses = await db.query('expenses', orderBy: 'date DESC');

    // Group expenses by month-year
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var exp in allExpenses) {
      final date = DateTime.parse(exp['date'] as String);
      final monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(monthKey, () => []).add(exp);
    }

    // Prepare monthly summary with top 3 categories
    List<Map<String, dynamic>> summary = [];
    grouped.forEach((month, expenses) {
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

    // optionally sort months descending
    summary.sort(
      (a, b) => (b['month'] as String).compareTo(a['month'] as String),
    );

    if (mounted) {
      setState(() {
        monthlyData = summary;
      });
    }
  }

  String formatMonth(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    final monthName = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month];
    return "$monthName $year";
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 2),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No monthly expenses to show',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Please add some expenses to view monthly expenses.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // IMPORTANT: shrinkWrap + non-scrollable physics so this LIST won't conflict
    // with an outer SingleChildScrollView (the typical cause of the "unbounded height" error).
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: monthlyData.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final monthInfo = monthlyData[index];
        final total = (monthInfo['total'] as num).toDouble();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month
                Text(
                  formatMonth(monthInfo['month'] as String),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // Total
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 12),

                // Top Categories
                const Text(
                  "Top 3 Categories:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                ...((monthInfo['topCategories'] as List).map<Widget>((
                  catEntry,
                ) {
                  // catEntry is MapEntry<String,double>
                  final category = catEntry.key.toString();
                  final value = (catEntry.value as num).toDouble();
                  final percent = total > 0 ? (value / total) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "\$${value.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ),
          ),
        );
      },
    );
  }
}
