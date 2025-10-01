// lib/shared/widgets/month_compare_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthCompareChart extends StatefulWidget {
  final List<Map<String, dynamic>> allExpenses;
  final List<String> availableMonths; // yyyy-MM strings (newest first)

  const MonthCompareChart({
    super.key,
    required this.allExpenses,
    required this.availableMonths,
  });

  @override
  State<MonthCompareChart> createState() => _MonthCompareChartState();
}

class _MonthCompareChartState extends State<MonthCompareChart> {
  late List<String> months;
  String? leftMonth;
  String? rightMonth;

  Map<int, double> leftData = {};
  Map<int, double> rightData = {};

  final leftColor = const Color(0xFF4CAF50);
  final rightColor = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    months = List<String>.from(widget.availableMonths);

    final now = DateTime.now();

    // Ensure at least 2 months exist
    if (months.isEmpty) {
      months = [
        DateFormat('yyyy-MM').format(now),
        DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1)),
      ];
    } else if (months.length == 1) {
      final parts = months.first.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final prev = DateTime(y, m - 1);
      months = [months.first, DateFormat('yyyy-MM').format(prev)];
    }

    // default compare newest vs previous
    leftMonth = months[0];
    rightMonth = months[1];

    _recomputeData();
  }

  void _recomputeData() {
    leftData = {for (var k = 1; k <= 30; k++) k: 0.0};
    rightData = {for (var k = 1; k <= 30; k++) k: 0.0};

    for (var row in widget.allExpenses) {
      final date = DateTime.parse(row['date'] as String);
      final ym = DateFormat('yyyy-MM').format(date);
      final day = date.day;
      final amt = (row['amount'] as num).toDouble();

      if (leftMonth != null && ym == leftMonth && day <= 30) {
        leftData[day] = (leftData[day]! + amt).clamp(0, double.infinity);
      }
      if (rightMonth != null && ym == rightMonth && day <= 30) {
        rightData[day] = (rightData[day]! + amt).clamp(0, double.infinity);
      }
    }

    setState(() {});
  }

  String _pretty(String ym) {
    final parts = ym.split('-');
    final y = int.parse(parts[0]), m = int.parse(parts[1]);
    return DateFormat('MMM yyyy').format(DateTime(y, m));
  }

  List<FlSpot> _spotsFromMap(Map<int, double> data) {
    return List.generate(
      30,
      (i) => FlSpot((i + 1).toDouble(), data[i + 1] ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftSpots = _spotsFromMap(leftData);
    final rightSpots = _spotsFromMap(rightData);

    final maxY = [
      ...leftData.values,
      ...rightData.values,
    ].fold<double>(0.0, (p, e) => e > p ? e : p);
    final yTop = (maxY == 0) ? 10.0 : (maxY * 1.2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Compare months',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: leftMonth,
                  items: months.map((m) {
                    return DropdownMenuItem(value: m, child: Text(_pretty(m)));
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      leftMonth = v;
                      _recomputeData();
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('vs'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: rightMonth,
                  items: months.map((m) {
                    return DropdownMenuItem(value: m, child: Text(_pretty(m)));
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      rightMonth = v;
                      _recomputeData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _legendDot(leftColor, _pretty(leftMonth!)),
                const SizedBox(width: 12),
                _legendDot(rightColor, _pretty(rightMonth!)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 30,
                  minY: 0,
                  maxY: yTop,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: (yTop / 4).clamp(1, double.infinity),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final v = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              v % 5 == 0 ? v.toString() : '',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12),
                      left: BorderSide(color: Colors.black12),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: leftSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: leftColor,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            leftColor.withOpacity(0.4),
                            leftColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: rightSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: rightColor,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            rightColor.withOpacity(0.4),
                            rightColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryTile(
                  _pretty(leftMonth!),
                  leftData.values.fold(0.0, (p, e) => p + e),
                ),
                _summaryTile(
                  _pretty(rightMonth!),
                  rightData.values.fold(0.0, (p, e) => p + e),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _summaryTile(String title, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        Text(
          '\$${total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
