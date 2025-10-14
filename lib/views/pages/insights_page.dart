import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/views/pages/insights/charts.dart';
import 'package:trackedify/views/pages/insights/heatmap.dart';
import 'package:trackedify/views/pages/insights/prediction_charts.dart';
import 'package:trackedify/views/pages/insights/summary_cards.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => InsightsPageState();
}

class InsightsPageState extends State<InsightsPage> {
  final DatabaseHelper dbHelper = DatabaseHelper();

  bool isLoading = false;

  double totalExpense = 0;
  Map<String, Map<String, dynamic>> categoryExpenses = {};
  List<Map<String, dynamic>> last30DaysExpenses = [];
  List<Map<String, dynamic>> last7DaysExpenses = [];
  Map<String, dynamic> insightsData = {};
  List<String> availableMonths = []; // 'yyyy-MM' strings
  List<Map<String, dynamic>> allExpenses = [];
  Map<String, Color> categoryColorMap = {};

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  void refresh() {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() {
      isLoading = true;
    });

    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> all = await db.query(
        'expenses',
        orderBy: 'date ASC',
      );

      // store all expenses locally
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
        final name = c['name'] as String;
        final colorVal = c['color'] as int;
        categoryColors[name] = Color(colorVal).withValues(alpha: 1.0);
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
          : freqCategory.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;

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
        categoryColorMap = categoryColors;
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error fetching expenses: $e\n$st');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load expenses: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Insights",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        body: Center(
          child: CupertinoActivityIndicator(radius: 12, color: cs.primary),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Insights",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        body: RefreshIndicator(
          color: cs.primary,
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
                Last30DaysChart(last30DaysExpenses: last30DaysExpenses),
                const SizedBox(height: 16),
                TwentyDaysWithPredictionChart(allExpenses: allExpenses),
                const SizedBox(height: 16),
                MonthCompareChart(
                  allExpenses: allExpenses,
                  availableMonths: availableMonths,
                ),
                const SizedBox(height: 16),
                CumulativeAreaChart(last30DaysExpenses: last30DaysExpenses),
                const SizedBox(height: 16),
                WeekdayBarChart(last30DaysExpenses: last30DaysExpenses),
                const SizedBox(height: 16),
                YearlyTrendChart(allExpenses: allExpenses),
                const SizedBox(height: 16),
                CategoryPieChart(categoryExpenses: categoryExpenses),
                const SizedBox(height: 16),
                TopCategoryChart(categoryExpenses: categoryExpenses),
                const SizedBox(height: 16),
                TopExpensesList(
                  allExpenses: allExpenses,
                  topN: 6,
                  categoryColors: categoryColorMap,
                ),
                const SizedBox(height: 16),
                ExpensesHeatmapCalendar(allExpenses: allExpenses),
              ],
            ),
          ),
        ),
      );
    }
  }
}
