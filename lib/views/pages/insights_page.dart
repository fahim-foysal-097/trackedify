// lib/screens/insights_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/widgets/expense_month_compare.dart.dart';
import 'package:spendle/shared/widgets/expense_summary_card.dart';
import 'package:spendle/shared/widgets/insights_cards.dart';
import 'package:spendle/shared/widgets/expense_line_chart.dart';
import 'package:spendle/shared/widgets/expense_bar_chart.dart';

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

    // Weekly average (last 7 days)
    double weeklyTotal = last7.fold(0.0, (p, e) => p + (e['amount'] as double));
    double weeklyAvg = weeklyTotal / 7;

    String mostFreqCategory = freqCategory.isEmpty
        ? "N/A"
        : freqCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Build month list from allExpenses
    final monthSet = <String>{};
    for (var e in all) {
      final dt = DateTime.parse(e['date'] as String);
      final ym = DateFormat('yyyy-MM').format(dt);
      monthSet.add(ym);
    }
    final months = monthSet.toList();
    months.sort((a, b) => b.compareTo(a)); // newest first

    setState(() {
      totalExpense = total;
      categoryExpenses = catMap;
      last30DaysExpenses = last30;
      last7DaysExpenses = last7;
      insightsData = {
        'maxExpense': maxExpense,
        'minExpense': minExpense == double.infinity ? 0 : minExpense,
        'mostFreqCategory': mostFreqCategory,
        'weeklyAvg': weeklyAvg,
      };
      availableMonths = months;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Insights"), centerTitle: true),
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
              ExpenseBarChart(last7DaysExpenses: last7DaysExpenses),
              const SizedBox(height: 20),
              MonthCompareChart(
                allExpenses: allExpenses,
                availableMonths: availableMonths,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
