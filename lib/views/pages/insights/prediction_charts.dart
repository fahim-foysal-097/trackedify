import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// -------------------- 20 DAYS WITH 10 DAYS PREDICTION --------------------

// * Uses Holt-Winters Forecasting

class TwentyDaysWithPredictionChart extends StatelessWidget {
  final List<Map<String, dynamic>> allExpenses;

  const TwentyDaysWithPredictionChart({super.key, required this.allExpenses});

  /// Fit additive Holt-Winters (level, trend, seasonal)
  /// - alpha, beta, gamma are smoothing params
  /// - period is seasonal period (e.g., 7 for weekly)
  Map<String, dynamic> _fitHoltWinters(
    List<double> data,
    double alpha,
    double beta,
    double gamma,
    int period,
  ) {
    int n = data.length;
    // Edge cases
    if (n == 0) {
      return {'level': 0.0, 'trend': 0.0, 'seasonal': List.filled(period, 0.0)};
    }

    // If series is effectively constant -> trivial fit
    double minVal = data.reduce(min);
    double maxVal = data.reduce(max);
    if ((maxVal - minVal).abs() < 1e-9) {
      return {
        'level': data.isNotEmpty ? data.last : 0.0,
        'trend': 0.0,
        'seasonal': List.filled(period, 0.0),
      };
    }

    // --- INITIAL LEVEL & TREND ---
    double initLevel;
    double initTrend;

    // Prefer classical init using averages of first two full seasons if possible
    if (n >= period * 2) {
      double avgFirst = 0.0;
      double avgSecond = 0.0;
      for (int i = 0; i < period; i++) {
        avgFirst += data[i];
        avgSecond += data[i + period];
      }
      avgFirst /= period;
      avgSecond /= period;
      initLevel = avgFirst;
      initTrend = (avgSecond - avgFirst) / period;
    } else {
      // fallback to linear regression
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (int t = 0; t < n; t++) {
        double x = t.toDouble();
        double y = data[t];
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      }
      double denom = n * sumX2 - sumX * sumX;
      initTrend = denom != 0 ? (n * sumXY - sumX * sumY) / denom : 0.0;
      initLevel = (sumY - initTrend * sumX) / n;
    }

    // --- INITIAL SEASONAL COMPONENTS (additive) ---
    // Detrend using initLevel + initTrend
    List<double> detrended = List.generate(
      n,
      (t) => data[t] - (initLevel + initTrend * t),
    );

    List<double> seasonal = List.filled(period, 0.0);
    List<int> counts = List.filled(period, 0);

    for (int t = 0; t < n; t++) {
      int idx = t % period;
      seasonal[idx] += detrended[t];
      counts[idx]++;
    }

    for (int s = 0; s < period; s++) {
      seasonal[s] = counts[s] > 0 ? seasonal[s] / counts[s] : 0.0;
    }

    // Normalize seasonal to zero mean (additive model)
    double meanSeason = seasonal.reduce((a, b) => a + b) / period;
    for (int s = 0; s < period; s++) {
      seasonal[s] -= meanSeason;
    }

    // If not enough data for seasonality, disable gamma and zero seasonal
    if (n < period) {
      gamma = 0.0;
      seasonal = List.filled(period, 0.0);
    }

    // --- RECURSIVE UPDATING ---
    double level = initLevel;
    double trend = initTrend;

    for (int t = 0; t < n; t++) {
      double sIdx = seasonal[t % period];
      double deseason = data[t] - sIdx;
      double newLevel = alpha * deseason + (1 - alpha) * (level + trend);
      double newTrend = beta * (newLevel - level) + (1 - beta) * trend;
      double newSeason = gamma > 0
          ? gamma * (data[t] - newLevel) + (1 - gamma) * sIdx
          : sIdx;
      level = newLevel;
      trend = newTrend;
      seasonal[t % period] = newSeason;
    }

    return {'level': level, 'trend': trend, 'seasonal': seasonal};
  }

  /// Forecast next [steps] values after [n] observed points using fitted components.
  /// For additive model:
  ///   F_{n+k} = level + k * trend + seasonal[(n + k -1) % period]
  List<double> _forecastFromFit(
    Map<String, dynamic> fit,
    int n,
    int steps,
    int period,
  ) {
    List<double> fc = [];
    double level = fit['level'] as double;
    double trend = fit['trend'] as double;
    List<double> seasonal = List<double>.from(fit['seasonal'] as List<double>);

    for (int k = 1; k <= steps; k++) {
      int seasonIndex =
          (n + k - 1) % period; // next time index is n, so k=1 -> n%period
      double f = level + k * trend + seasonal[seasonIndex];
      if (f.isNaN || f.isInfinite) f = 0.0;
      fc.add(f < 0 ? 0.0 : f); // clamp negative forecasts to 0
    }
    return fc;
  }

  /// Mean squared error
  double _mse(List<double> actual, List<double> pred) {
    if (actual.isEmpty || pred.isEmpty) return double.infinity;
    double sum = 0.0;
    int m = min(actual.length, pred.length);
    for (int i = 0; i < m; i++) {
      double e = actual[i] - pred[i];
      sum += e * e;
    }
    return sum / m;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (allExpenses.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No data available for prediction chart.',
            style: TextStyle(color: cs.onSurface),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final dayNow = DateTime(now.year, now.month, now.day);

    // Fit window: use up to last 60 days (but not more than available)
    final startFitDate = dayNow.subtract(const Duration(days: 60));

    // Aggregate daily totals (robust parsing: accept String or DateTime)
    final Map<DateTime, double> daily = {};
    for (var e in allExpenses) {
      final dynamic dtRaw = e['date'];
      DateTime dt;
      if (dtRaw is DateTime) {
        dt = dtRaw;
      } else if (dtRaw is String) {
        // try parse; ignore invalid
        try {
          dt = DateTime.parse(dtRaw);
        } catch (err) {
          continue;
        }
      } else {
        continue;
      }
      final day = DateTime(dt.year, dt.month, dt.day);
      if (!day.isBefore(startFitDate) && !day.isAfter(dayNow)) {
        daily[day] = (daily[day] ?? 0.0) + (e['amount'] as num).toDouble();
      }
    }

    // Build continuous historical list from startFitDate .. dayNow (fill zero for missing days)
    List<double> historical = [];
    DateTime current = startFitDate;
    while (!current.isAfter(dayNow)) {
      historical.add(daily[current] ?? 0.0);
      current = current.add(const Duration(days: 1));
    }

    int n = historical.length;
    if (n < 1) {
      return Container(
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No data available for prediction chart.',
            style: TextStyle(color: cs.onError),
          ),
        ),
      );
    }

    // If all zeros in historical, short-circuit
    bool allZero = true;
    for (var v in historical) {
      if (v.abs() > 1e-9) {
        allZero = false;
        break;
      }
    }
    if (allZero) {
      List<double> zeros = List.filled(10, 0.0);
      // show last up-to-20 days (will be all zeros)
      int histShowStart = max(0, n - 20);
      int histShowLen = n - histShowStart;
      List<FlSpot> histSpots = List.generate(
        histShowLen,
        (i) => FlSpot(i.toDouble(), historical[histShowStart + i]),
      );
      List<FlSpot> predSpots = [
        histSpots.isNotEmpty ? histSpots.last : const FlSpot(0, 0),
      ];
      for (int i = 0; i < 10; i++) {
        predSpots.add(FlSpot((histShowLen + i).toDouble(), zeros[i]));
      }

      double maxY = 100.0;
      double intervalY = (maxY / 5).ceilToDouble();

      DateTime chartStart = dayNow.subtract(Duration(days: histShowLen - 1));
      int totalPoints = histShowLen + 10;
      final double predStartX = histShowLen.toDouble();

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Expenses Trend - Last 20 Days with Next 10 Prediction",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY + intervalY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: intervalY,
                    verticalInterval: 3,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 3,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt().clamp(0, totalPoints - 1);
                          final date = chartStart.add(Duration(days: index));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: intervalY,
                        getTitlesWidget: (value, meta) => Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    verticalLines: [
                      VerticalLine(
                        x: histShowLen - 0.5,
                        color: Colors.grey.withValues(alpha: 0.8),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: VerticalLineLabel(
                          show: true,
                          alignment: Alignment.topLeft,
                          direction: LabelDirection.horizontal,
                          labelResolver: (line) => 'Today',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: histSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 0,
                      isStrokeJoinRound: true,
                      isStrokeCapRound: true,
                      color: Colors.deepPurpleAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurpleAccent.withValues(alpha: 0.5),
                            Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    LineChartBarData(
                      spots: predSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      preventCurveOvershootingThreshold: 0,
                      isStrokeJoinRound: true,
                      isStrokeCapRound: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent.withValues(alpha: 0.3),
                            Colors.blueAccent.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final bool isPredict = spot.x >= predStartX;
                          final x = spot.x.toInt();
                          final date = chartStart.add(Duration(days: x));
                          final dateStr = DateFormat(
                            'MMM d, yyyy',
                          ).format(date);
                          final y = spot.y;
                          final prefix = isPredict ? 'Predicted\n' : '';
                          return LineTooltipItem(
                            '$prefix$dateStr\n\$${y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Next day (${DateFormat('MMM d').format(dayNow.add(const Duration(days: 1)))}) predicted expense: \$0.00',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Holt-Winters params defaults
    const int period = 7;
    double alpha = 0.3;
    double beta = 0.1;
    double gamma = 0.3;

    // If we have enough points, tune parameters using a simple grid search (with refinement)
    if (n > 30) {
      // Reserve last 10 days for validation
      int validationHorizon = 10;
      int trainLen = max(10, n - validationHorizon);
      List<double> trainData = historical.sublist(0, trainLen);
      List<double> valActual = historical.sublist(
        trainLen,
        min(n, trainLen + validationHorizon),
      );

      // Only search if we have at least two full seasons in training to learn seasonality
      if (trainLen >= period * 2) {
        double bestMse = double.infinity;
        double bestA = alpha, bestB = beta, bestG = gamma;

        // coarse grid
        List<double> grid = [0.05, 0.15, 0.3, 0.5, 0.7, 0.9];
        for (double a in grid) {
          for (double b in grid) {
            for (double g in grid) {
              var fit = _fitHoltWinters(trainData, a, b, g, period);
              var pred = _forecastFromFit(
                fit,
                trainLen,
                valActual.length,
                period,
              );
              double mse = _mse(valActual, pred);
              if (mse.isFinite && mse < bestMse) {
                bestMse = mse;
                bestA = a;
                bestB = b;
                bestG = g;
                if (bestMse < 1e-6) break;
              }
            }
            if (bestMse < 1e-6) break;
          }
          if (bestMse < 1e-6) break;
        }

        // local refinement around best using small steps
        double refineStep = 0.05;
        for (
          double a = max(0.01, bestA - refineStep);
          a <= min(0.99, bestA + refineStep);
          a += refineStep
        ) {
          for (
            double b = max(0.01, bestB - refineStep);
            b <= min(0.99, bestB + refineStep);
            b += refineStep
          ) {
            for (
              double g = max(0.0, bestG - refineStep);
              g <= min(0.99, bestG + refineStep);
              g += refineStep
            ) {
              var fit = _fitHoltWinters(trainData, a, b, g, period);
              var pred = _forecastFromFit(
                fit,
                trainLen,
                valActual.length,
                period,
              );
              double mse = _mse(valActual, pred);
              if (mse.isFinite && mse < bestMse) {
                bestMse = mse;
                bestA = a;
                bestB = b;
                bestG = g;
              }
            }
          }
        }

        alpha = bestA;
        beta = bestB;
        gamma = bestG;
      }
    }

    // Fit on entire historical using chosen params
    var fitAll = _fitHoltWinters(historical, alpha, beta, gamma, period);
    List<double> forecasts = _forecastFromFit(fitAll, n, 10, period);

    // Show last up-to-20 historical days
    int histShowStart = max(0, n - 20);
    int histShowLen = n - histShowStart;
    List<FlSpot> histSpots = [];
    for (int i = 0; i < histShowLen; i++) {
      histSpots.add(FlSpot(i.toDouble(), historical[histShowStart + i]));
    }

    // For continuity include the last historical point as starting anchor for predicted series
    List<FlSpot> predSpots = [];
    if (histSpots.isNotEmpty) {
      predSpots.add(FlSpot(histSpots.last.x, histSpots.last.y));
    } else {
      predSpots.add(const FlSpot(0, 0));
    }
    for (int i = 0; i < forecasts.length; i++) {
      predSpots.add(FlSpot((histShowLen + i).toDouble(), forecasts[i]));
    }

    // Chart maxY
    double maxY = 0;
    for (var s in histSpots) {
      maxY = max(maxY, s.y);
    }
    for (var s in predSpots) {
      maxY = max(maxY, s.y);
    }
    maxY = maxY > 0 ? maxY : 100.0;
    double intervalY = (maxY / 5).ceilToDouble();
    intervalY = intervalY > 0 ? intervalY : 1.0;
    double chartMaxY = maxY + intervalY;

    // Chart start date (x=0 -> earliest shown day)
    DateTime chartStart = dayNow.subtract(Duration(days: histShowLen - 1));
    int totalPoints = histShowLen + 10;
    final double predStartX = histShowLen.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Expenses Trend - Last 20 Days with Next 10 Prediction",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: intervalY,
                  verticalInterval: 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt().clamp(0, totalPoints - 1);
                        final date = chartStart.add(Duration(days: index));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: intervalY,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: histShowLen - 0.5,
                      color: Colors.grey.withValues(alpha: 0.8),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        direction: LabelDirection.horizontal,
                        labelResolver: (line) => 'Today',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: histSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    preventCurveOvershootingThreshold: 0,
                    isStrokeJoinRound: true,
                    isStrokeCapRound: true,
                    color: Colors.deepPurpleAccent,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurpleAccent.withValues(alpha: 0.5),
                          Colors.deepPurpleAccent.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: predSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    preventCurveOvershootingThreshold: 0,
                    isStrokeJoinRound: true,
                    isStrokeCapRound: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withValues(alpha: 0.3),
                          Colors.blueAccent.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => Colors.black87,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final bool isPredict = spot.x >= predStartX;
                        final x = spot.x.toInt();
                        final date = chartStart.add(Duration(days: x));
                        final dateStr = DateFormat('MMM d, yyyy').format(date);
                        final y = spot.y;
                        final prefix = isPredict ? 'Predicted\n' : '';
                        return LineTooltipItem(
                          '$prefix$dateStr\n\$${y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next day (${DateFormat('MMM d').format(dayNow.add(const Duration(days: 1)))}) predicted expense: \$${forecasts[0].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
