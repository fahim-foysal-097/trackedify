import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/database/models/category.dart';

class MyPieChart extends StatefulWidget {
  const MyPieChart({super.key});

  @override
  State<MyPieChart> createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  Map<String, double> categoryTotals = {};
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final data = await db.query('expenses');

    Map<String, double> totals = {};
    for (var row in data) {
      final category = row['category'] as String;
      final amount = (row['amount'] as num).toDouble();
      totals[category] = (totals[category] ?? 0) + amount;
    }

    setState(() {
      categoryTotals = totals;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No data for pie chart'));
    }

    final sections = categoryTotals.entries.toList().asMap().entries.map((
      entry,
    ) {
      final index = entry.key;
      final data = entry.value;
      final cat = categories.firstWhere(
        (c) => c.name == data.key,
        orElse: () =>
            Category(name: data.key, color: Colors.grey, icon: Icons.category),
      );

      final isTouched = index == touchedIndex;

      return PieChartSectionData(
        color: cat.color,
        value: data.value,
        radius: isTouched ? 130 : 110,
        title: isTouched ? '\$${data.value.toStringAsFixed(0)}' : '',
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 0,
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
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: categoryTotals.entries.toList().asMap().entries.map((
            entry,
          ) {
            final index = entry.key;
            final data = entry.value;
            final cat = categories.firstWhere(
              (c) => c.name == data.key,
              orElse: () => Category(
                name: data.key,
                color: Colors.grey,
                icon: Icons.category,
              ),
            );

            final isSelected = touchedIndex == index;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(width: 2, color: Colors.black)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${cat.name} (\$${data.value.toStringAsFixed(0)})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[800],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
