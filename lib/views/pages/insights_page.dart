import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/widgets/expense_bar_chart.dart';
import 'package:spendle/shared/widgets/expense_line_chart.dart';
import 'package:spendle/shared/widgets/expense_pie_chart.dart';
import 'package:spendle/shared/widgets/expense_summary_card.dart';
import 'package:spendle/shared/widgets/insights_cards.dart';

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
    final List<Map<String, dynamic>> allExpenses = await db.query(
      'expenses',
      orderBy: 'date ASC',
    );
    final categories = await db.query('categories');

    double total = 0;
    Map<String, Map<String, dynamic>> catMap = {};
    List<Map<String, dynamic>> last30 = [];
    List<Map<String, dynamic>> last7 = [];
    final now = DateTime.now();

    double maxExpense = 0;
    double minExpense = double.infinity;
    Map<String, int> freqCategory = {};

    // Build category color mapping
    Map<String, Color> categoryColors = {};
    for (var c in categories) {
      categoryColors[c['name'] as String] = Color(
        c['color'] as int,
      ).withValues(alpha: 0.9);
    }

    for (var e in allExpenses) {
      double amt = e['amount'] as double;
      String cat = e['category'] as String;
      DateTime dt = DateTime.parse(e['date']);

      total += amt;

      if (catMap.containsKey(cat)) {
        catMap[cat]!['amount'] += amt;
      } else {
        catMap[cat] = {'amount': amt, 'color': categoryColors[cat]};
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Insights"),
        centerTitle: true,
        // backgroundColor: Colors.blue,
      ),
      body: RefreshIndicator(
        onRefresh: fetchExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ExpenseSummaryCard(totalExpense: totalExpense),
              const SizedBox(height: 20),
              InsightsCards(insights: insightsData),
              const SizedBox(height: 20),
              ExpensePieChart(categoryExpenses: categoryExpenses),
              const SizedBox(height: 20),
              ExpenseLineChart(last30DaysExpenses: last30DaysExpenses),
              const SizedBox(height: 20),
              ExpenseBarChart(last7DaysExpenses: last7DaysExpenses),
            ],
          ),
        ),
      ),
    );
  }
}
