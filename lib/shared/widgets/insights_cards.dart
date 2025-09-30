import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InsightsCards extends StatelessWidget {
  final Map<String, dynamic> insights;
  const InsightsCards({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: "\$");

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildCard(
            title: "Max Expense",
            value: insights['maxExpense'] ?? 0,
            color: Colors.red,
            formatter: formatter,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            title: "Min Expense",
            value: insights['minExpense'] ?? 0,
            color: Colors.green,
            formatter: formatter,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCard(
            title: "Most Frequent",
            valueText: insights['mostFreqCategory'] ?? "N/A",
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    double? value,
    String? valueText,
    required Color color,
    NumberFormat? formatter,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            value != null ? formatter!.format(value) : valueText ?? "",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
