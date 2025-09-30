import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensePieChart extends StatefulWidget {
  final Map<String, Map<String, dynamic>> categoryExpenses;
  const ExpensePieChart({super.key, required this.categoryExpenses});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.categoryExpenses.values.fold(
      0.0,
      (sum, e) => sum + (e['amount'] as double),
    );

    final entries = widget.categoryExpenses.entries.toList();

    final sections = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final cat = entry.value.value;
      final value = cat['amount'] as double;
      final color = cat['color'] as Color;
      final isTouched = index == touchedIndex;

      return PieChartSectionData(
        color: color,
        value: value,
        radius: isTouched ? 70 : 60,
        title: isTouched ? '\$${value.toStringAsFixed(2)}' : '',
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Expenses by Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          touchedIndex = null;
                          return;
                        }
                        touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final cat = entry.value.value;
                final name = entry.value.key;
                final value = cat['amount'] as double;
                final color = cat['color'] as Color;
                final percent = total == 0 ? 0 : (value / total * 100);
                final isSelected = touchedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      touchedIndex = isSelected ? null : index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey.shade200 : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 14, height: 14, color: color),
                        const SizedBox(width: 6),
                        Text(
                          '$name (${percent.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
