import 'package:flutter/material.dart';
import 'package:spendle/views/pages/stats/bar_chart.dart';
import 'package:spendle/views/pages/stats/monthly_overview.dart';
import 'package:spendle/views/pages/stats/pie_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [SizedBox(height: 20), MyPieChart()],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Monthly tab ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const Column(
                        children: [SizedBox(height: 8), MonthlyOverviewTab()],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Last 7 Days tab ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: const Column(
                        children: [SizedBox(height: 8), MyBarChart()],
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
