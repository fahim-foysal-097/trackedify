import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// -------------------- EXPENSE SUMMARY & INSIGHTS --------------------

class ExpenseSummaryCard extends StatelessWidget {
  final double totalExpense;
  const ExpenseSummaryCard({super.key, required this.totalExpense});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: "\$");
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.lightBlueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Expense",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                formatter.format(totalExpense),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Icon(Icons.pie_chart, color: Colors.white, size: 36),
        ],
      ),
    );
  }
}

class InsightsCards extends StatelessWidget {
  final Map<String, dynamic> insights;
  const InsightsCards({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: "\$");

    double safeDouble(Object? o) => (o as num?)?.toDouble() ?? 0.0;

    final percent = safeDouble(insights['percentChange']);
    final percentLabel = percent.isFinite
        ? '${percent.toStringAsFixed(1)}%'
        : '—';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildCard(
                title: "Max Expense",
                value: safeDouble(insights['maxExpense']),
                color: Colors.red,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Min Expense",
                value: safeDouble(insights['minExpense']),
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
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildCard(
                title: "Weekly Avg",
                value: safeDouble(insights['weeklyAvg']),
                color: Colors.purple,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Current Month",
                value: safeDouble(insights['currentMonth']),
                color: Colors.blue,
                formatter: formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                title: "Trend",
                valueText: percentLabel,
                // color: red when spending increased vs previous month (bad), green when decreased (good)
                color: percent >= 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(16),
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value != null ? formatter!.format(value) : valueText ?? "",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
