import 'package:flutter/material.dart';
import 'package:spendle/views/stats/bar_chart.dart';
import 'package:spendle/views/stats/pie_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsGeometry.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Charts",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(4),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width,
                child: const MyBarChart(),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(4),
                child: const MyPieChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
