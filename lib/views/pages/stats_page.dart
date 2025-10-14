import 'package:flutter/material.dart';
import 'package:trackedify/views/pages/stats/last7days_stats.dart';
import 'package:trackedify/views/pages/stats/monthly_overview.dart';
import 'package:trackedify/views/pages/stats/all_time_stats.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  // for refreshing
  final GlobalKey<AllTimeStatsState> _pieKey = GlobalKey<AllTimeStatsState>();
  final GlobalKey<MonthlyOverviewTabState> _monthlyKey =
      GlobalKey<MonthlyOverviewTabState>();
  final GlobalKey<Last7daysStatsState> _barKey =
      GlobalKey<Last7daysStatsState>();

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
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Statistics",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          bottom: TabBar(
            indicatorColor: cs.primary,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.7),
            automaticIndicatorColorAdjustment: true,
            tabs: const [
              Tab(text: "All Time"),
              Tab(text: "Monthly"),
              Tab(text: "Last 7 Days"),
            ],
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: Theme.of(context).appBarTheme.elevation ?? 4,
        ),
        body: TabBarView(
          children: [
            // --- All Time tab ---
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return RefreshIndicator(
                    color: cs.primary,
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
                            AllTimeStats(key: _pieKey),
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
                    color: cs.primary,
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
                    color: cs.primary,
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
                            Last7daysStats(key: _barKey),
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
