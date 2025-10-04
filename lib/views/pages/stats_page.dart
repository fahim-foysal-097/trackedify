import 'package:flutter/material.dart';
import 'package:spendle/views/pages/stats/bar_chart.dart';
import 'package:spendle/views/pages/stats/monthly_overview.dart';
import 'package:spendle/views/pages/stats/pie_chart.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  final GlobalKey<MyPieChartState> _pieKey = GlobalKey<MyPieChartState>();
  final GlobalKey<MonthlyOverviewTabState> _monthlyKey =
      GlobalKey<MonthlyOverviewTabState>();
  final GlobalKey<MyBarChartState> _barKey = GlobalKey<MyBarChartState>();

  Future<void> refreshAll() async {
    final futures = <Future<void>>[];
    if (_pieKey.currentState != null) {
      futures.add(_pieKey.currentState!.loadCategoriesAndExpenses());
    }
    if (_monthlyKey.currentState != null) {
      futures.add(_monthlyKey.currentState!.loadMonthlyData());
    }
    if (_barKey.currentState != null) {
      futures.add(_barKey.currentState!.loadExpenses());
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Statistics",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.deepPurpleAccent,
            labelColor: Colors.deepPurple,
            automaticIndicatorColorAdjustment: true,
            
            tabs: [
              Tab(text: "All Time"),
              Tab(text: "Monthly"),
              Tab(text: "Last 7 Days"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- All Time tab ---
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    color: Colors.deepPurpleAccent,
                    onRefresh: refreshAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            MyPieChart(key: _pieKey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Monthly tab ---
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    color: Colors.deepPurpleAccent,
                    onRefresh: refreshAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            MonthlyOverviewTab(key: _monthlyKey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Last 7 Days tab ---
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                right: 10.0,
                bottom: 4.0,
                top: 4.0,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    color: Colors.deepPurpleAccent,
                    onRefresh: refreshAll,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            MyBarChart(key: _barKey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
