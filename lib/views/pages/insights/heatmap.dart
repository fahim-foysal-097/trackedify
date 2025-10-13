import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';

class ExpensesHeatmapCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> allExpenses;
  const ExpensesHeatmapCalendar({super.key, required this.allExpenses});

  @override
  State<ExpensesHeatmapCalendar> createState() =>
      _ExpensesHeatmapCalendarState();
}

class _ExpensesHeatmapCalendarState extends State<ExpensesHeatmapCalendar> {
  Map<DateTime, double> dailyTotals = {};
  DateTime? minDate;
  late DateTime maxDate;
  late DateTime currentStartDate;
  late DateTime currentEndDate;
  late DateTime minStart;
  late DateTime maxStart;
  Map<DateTime, int> datasets = {};
  double maxDaily = 0.0;

  @override
  void initState() {
    super.initState();
    maxDate = DateTime.now();
    _computeDailyTotals();
    if (minDate != null) {
      minStart = DateTime(minDate!.year, minDate!.month, 1);
      maxStart = _addMonths(maxDate, -5);
      currentStartDate = maxStart;
      currentEndDate = _getEndForStart(currentStartDate);
    }
  }

  void _computeDailyTotals() {
    dailyTotals = {};
    minDate = null;

    for (var e in widget.allExpenses) {
      DateTime dt = DateTime.parse(e['date'] as String);
      DateTime day = DateTime(dt.year, dt.month, dt.day);
      double amount = (e['amount'] as num).toDouble();
      dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;

      if (minDate == null || day.isBefore(minDate!)) {
        minDate = day;
      }
    }

    if (dailyTotals.values.isNotEmpty) {
      maxDaily = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    }

    if (maxDaily > 0) {
      dailyTotals.forEach((date, sum) {
        if (sum > 0) {
          int level = ((sum / maxDaily) * 100).round();
          datasets[date] = level;
        }
      });
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    int year = date.year;
    int month = date.month + months;
    int day = 1;
    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }
    return DateTime(year, month, day);
  }

  DateTime _getEndForStart(DateTime start) {
    DateTime endMonthStart = _addMonths(start, 6);
    int endYear = endMonthStart.year;
    int endMonth = endMonthStart.month;
    int lastDay = DateTime(endYear, endMonth + 1, 0).day;
    DateTime end = DateTime(endYear, endMonth, lastDay);
    if (end.isAfter(maxDate)) {
      end = maxDate;
    }
    return end;
  }

  void _previousPeriod() {
    setState(() {
      DateTime newStart = _addMonths(currentStartDate, -6);
      if (newStart.isBefore(minStart)) {
        newStart = minStart;
      }
      currentStartDate = newStart;
      currentEndDate = _getEndForStart(currentStartDate);
    });
  }

  void _nextPeriod() {
    setState(() {
      DateTime newStart = _addMonths(currentStartDate, 6);
      currentStartDate = newStart;
      currentEndDate = _getEndForStart(currentStartDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allExpenses.isEmpty || minDate == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No data available for heatmap calendar.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    int totalDays = currentEndDate.difference(currentStartDate).inDays + 1;
    int numColumns = (totalDays - 1) ~/ 7 + 1;
    double availableWidth = MediaQuery.of(context).size.width - 32;
    double cellMarginHorizontal = 4.0;
    double cellSize = (availableWidth / numColumns) - cellMarginHorizontal + 8;
    double fontSize = cellSize * 0.6;

    String rangeText =
        '${DateFormat('MMM yyyy').format(currentStartDate)} - ${DateFormat('MMM yyyy').format(currentEndDate)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Expenses Heatmap",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: currentStartDate.isAfter(minStart)
                    ? _previousPeriod
                    : null,
              ),
              Expanded(
                child: Text(
                  rangeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: currentStartDate.isBefore(maxStart)
                    ? _nextPeriod
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cellSize * 7 + 150,
            child: HeatMap(
              datasets: datasets,
              colorMode: ColorMode.opacity,
              showText: false,
              scrollable: true,
              colorsets: const {100: Colors.red},
              defaultColor: Colors.grey[200],
              textColor: Colors.black,
              showColorTip: true,
              size: cellSize,
              fontSize: fontSize,
              margin: const EdgeInsets.all(2),
              borderRadius: 4,
              startDate: currentStartDate,
              endDate: currentEndDate,
            ),
          ),
        ],
      ),
    );
  }
}
