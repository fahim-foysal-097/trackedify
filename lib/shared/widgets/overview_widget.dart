import 'package:flutter/material.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/theme_controller.dart';

class OverviewWidget extends StatefulWidget {
  const OverviewWidget({super.key});

  @override
  State<OverviewWidget> createState() => OverviewWidgetState();
}

class OverviewWidgetState extends State<OverviewWidget> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void refresh() {
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      _future = _loadOverview();
    });
  }

  Future<Map<String, dynamic>> _loadOverview() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('expenses');

    double totalExpenses = 0;
    final Map<String, double> monthlyTotals = {};

    for (var row in rows) {
      final amount = (row['amount'] as num).toDouble();
      final dateStr = row['date'] as String;
      totalExpenses += amount;

      String monthKey;
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        monthKey =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
      } else {
        final parts = dateStr.split(RegExp(r'[-/]'));
        if (parts.length >= 2) {
          final year = parts[0].padLeft(4, '0');
          final month = parts[1].padLeft(2, '0');
          monthKey = '$year-$month';
        } else {
          monthKey = dateStr;
        }
      }
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
    }

    double avgMonthly = 0;
    if (monthlyTotals.isNotEmpty) {
      final totalPerMonth = monthlyTotals.values.reduce((a, b) => a + b);
      avgMonthly = totalPerMonth / monthlyTotals.length;
    }

    // Calculate trend % (compared to previous month)
    double trendPercent = 0;
    if (monthlyTotals.length > 1) {
      final sortedMonths = monthlyTotals.keys.toList()..sort();
      final lastMonth = sortedMonths.last;
      final prevMonth = sortedMonths[sortedMonths.length - 2];

      final lastAmount = monthlyTotals[lastMonth]!;
      final prevAmount = monthlyTotals[prevMonth]!;
      if (prevAmount != 0) {
        trendPercent = ((lastAmount - prevAmount) / prevAmount) * 100;
      } else {
        trendPercent = 100; // fallback if previous month is zero
      }
    }

    return {
      'totalExpenses': totalExpenses,
      'averageMonthly': avgMonthly,
      'totalTransactions': rows.length,
      'trendPercent': trendPercent,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Constants for responsive sizing
    const double baseWidth = 420; // design width
    const double maxCardWidth = 640; // max width on large screens
    const double horizontalPadding = 24; // outside padding

    final ctrl = ThemeController.instance;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        double totalExpenses = 0;
        double averageMonthly = 0;
        int totalTransactions = 0;
        double trendPercent = 0;

        if (snapshot.hasData) {
          totalExpenses = snapshot.data!['totalExpenses'] as double;
          averageMonthly = snapshot.data!['averageMonthly'] as double;
          totalTransactions = snapshot.data!['totalTransactions'] as int;
          trendPercent = snapshot.data!['trendPercent'] as double;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // When parent gives infinite width (rare), fallback to screen width
            final screenWidth = MediaQuery.of(context).size.width;
            final availableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : screenWidth;

            // Reserve horizontal padding, clamp width to a maximum
            final usableWidth = (availableWidth - (horizontalPadding * 2))
                .clamp(0.0, maxCardWidth);

            // Ensure a minimum width so the card doesn't collapse on very small screens
            final cardWidth = usableWidth.clamp(280.0, maxCardWidth);

            // scaleFactor derived from cardWidth relative to base design width
            final scaleFactor = (cardWidth / baseWidth).clamp(0.6, 1.5);

            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 200, 20, 2),
                child: SizedBox(
                  width: cardWidth,
                  // maintain aspect ratio
                  child: AspectRatio(
                    aspectRatio: 1.75,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ctrl.effectiveColorForRole(context, 'overview-1'),
                            ctrl.effectiveColorForRole(context, 'overview-2'),
                            ctrl.effectiveColorForRole(context, 'overview-3'),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20 * scaleFactor),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.28),
                            blurRadius: 5 * scaleFactor,
                            offset: Offset(0, 8 * scaleFactor),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(18 * scaleFactor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: cs.onPrimary,
                                  size: 28 * scaleFactor,
                                ),
                                SizedBox(width: 12 * scaleFactor),
                                Expanded(
                                  child: Text(
                                    'Expense Overview',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: cs.onPrimary,
                                          fontSize: 18 * scaleFactor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20 * scaleFactor),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _StatItem(
                                          icon: Icons.trending_up_rounded,
                                          label: 'Total Spent',
                                          value:
                                              '\$${totalExpenses.toStringAsFixed(2)}',
                                          isRightAligned: false,
                                          scaleFactor: scaleFactor,
                                        ),
                                        SizedBox(height: 5 * scaleFactor),
                                        Text(
                                          trendPercent >= 0
                                              ? '+${trendPercent.toStringAsFixed(1)}%'
                                              : '${trendPercent.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: trendPercent <= 0
                                                ? Colors.greenAccent
                                                : Colors.yellowAccent,
                                            fontSize: 16 * scaleFactor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16 * scaleFactor),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _StatItem(
                                          icon: Icons.receipt_long,
                                          label: 'Transactions',
                                          value: totalTransactions.toString(),
                                          isRightAligned: true,
                                          scaleFactor: scaleFactor,
                                        ),
                                        SizedBox(height: 8 * scaleFactor),
                                        _StatItem(
                                          icon: Icons.calendar_month,
                                          label: 'Avg Monthly',
                                          value:
                                              '\$${averageMonthly.toStringAsFixed(2)}',
                                          isRightAligned: true,
                                          scaleFactor: scaleFactor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isRightAligned;
  final double scaleFactor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isRightAligned = false,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyleLabel = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cs.onPrimary.withValues(alpha: 0.88),
    );
    final textStyleValue = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: cs.onPrimary,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: isRightAligned
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isRightAligned
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isRightAligned) ...[
              Icon(
                icon,
                color: cs.onPrimary.withValues(alpha: 0.85),
                size: 20 * scaleFactor,
              ),
              SizedBox(width: 6 * scaleFactor),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: textStyleLabel?.copyWith(fontSize: 12 * scaleFactor),
              ),
            ),
            if (isRightAligned) ...[
              SizedBox(width: 6 * scaleFactor),
              Icon(
                icon,
                color: cs.onPrimary.withValues(alpha: 0.85),
                size: 20 * scaleFactor,
              ),
            ],
          ],
        ),
        SizedBox(height: 4 * scaleFactor),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: textStyleValue?.copyWith(fontSize: 20 * scaleFactor),
        ),
      ],
    );
  }
}
