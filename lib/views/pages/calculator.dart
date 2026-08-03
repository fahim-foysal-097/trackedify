import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class ExpenseCalculator extends StatefulWidget {
  final ValueChanged<double> onResult;

  const ExpenseCalculator({super.key, required this.onResult});

  @override
  State<ExpenseCalculator> createState() => _ExpenseCalculatorState();
}

class _ExpenseCalculatorState extends State<ExpenseCalculator> {
  static final ExpressionParser _parser = GrammarParser();

  String _expression = '';
  String _result = '0';

  void _append(String value) {
    // Block negative sign at start
    if (_expression.isEmpty && value == '-') return;

    setState(() {
      _expression += value;
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _result = '0';
    });
  }

  void _delete() {
    if (_expression.isNotEmpty) {
      setState(() {
        _expression = _expression.substring(0, _expression.length - 1);
      });
    }
  }

  void _calculate() {
    if (_expression.isEmpty) return;

    try {
      String exp = _expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Handle simple percentages (e.g., 100 + 20% or 100 - 20%)
      exp = exp.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?)([\+\-])(\d+(\.\d+)?)%'),
        (match) {
          final num1 = double.parse(match.group(1)!);
          final op = match.group(3)!;
          final percent = double.parse(match.group(4)!);
          final value = num1 * percent / 100;
          return '$num1$op$value';
        },
      );

      // Handle standalone percentages (e.g., 20%)
      exp = exp.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?)%'),
        (match) => '(${match.group(1)!}/100)',
      );

      final Expression parsedExp = _parser.parse(exp);
      final ContextModel cm = ContextModel();
      final RealEvaluator evaluator = RealEvaluator(cm);
      final double eval = evaluator.evaluate(parsedExp).toDouble();

      // Prevent negative or invalid math results for expenses
      if (eval.isNaN || eval.isInfinite || eval < 0) {
        setState(() {
          _result = 'Error';
          _expression = '';
        });
        return;
      }

      setState(() {
        _result = eval.toStringAsFixed(2);
        _expression = _result; // Allow chained calculations
      });

      widget.onResult(eval);
    } catch (_) {
      setState(() {
        _result = 'Error';
        _expression = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final width = MediaQuery.sizeOf(context).width;
    final buttonHeight = width > 420 ? 70.0 : 60.0;

    final opBg = cs.primaryContainer;
    final opFg = cs.onPrimaryContainer;

    final equalsBg = cs.primary;
    final equalsFg = cs.onPrimary;

    final clearBg = cs.errorContainer;
    final clearFg = cs.onErrorContainer;

    final backBg = cs.tertiaryContainer;
    final backFg = cs.onTertiaryContainer;

    final numberBg = cs.surfaceContainerHigh;
    final numberFg = cs.onSurface;

    final mutedBg = cs.surfaceContainer;
    final mutedFg = cs.onSurfaceVariant;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display Area
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression.isEmpty ? '0' : _expression,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _result,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 24, thickness: 1, color: cs.outlineVariant),

            // Keypad Grid Rows
            _buildRow([
              _CalcButtonData('C', bg: clearBg, fg: clearFg, onTap: _clear),
              _CalcButtonData('⌫', bg: backBg, fg: backFg, onTap: _delete),
              _CalcButtonData(
                '%',
                bg: opBg,
                fg: opFg,
                onTap: () {
                  if (_expression.isNotEmpty) {
                    _append('%');
                    _calculate();
                  }
                },
              ),
              _CalcButtonData('÷', bg: opBg, fg: opFg),
            ], buttonHeight),

            _buildRow([
              _CalcButtonData('7', bg: numberBg, fg: numberFg),
              _CalcButtonData('8', bg: numberBg, fg: numberFg),
              _CalcButtonData('9', bg: numberBg, fg: numberFg),
              _CalcButtonData('×', bg: opBg, fg: opFg),
            ], buttonHeight),

            _buildRow([
              _CalcButtonData('4', bg: numberBg, fg: numberFg),
              _CalcButtonData('5', bg: numberBg, fg: numberFg),
              _CalcButtonData('6', bg: numberBg, fg: numberFg),
              _CalcButtonData('-', bg: opBg, fg: opFg),
            ], buttonHeight),

            _buildRow([
              _CalcButtonData('1', bg: numberBg, fg: numberFg),
              _CalcButtonData('2', bg: numberBg, fg: numberFg),
              _CalcButtonData('3', bg: numberBg, fg: numberFg),
              _CalcButtonData('+', bg: opBg, fg: opFg),
            ], buttonHeight),

            _buildRow([
              _CalcButtonData('(', bg: mutedBg, fg: mutedFg),
              _CalcButtonData('0', bg: numberBg, fg: numberFg),
              _CalcButtonData('.', bg: numberBg, fg: numberFg),
              _CalcButtonData(')', bg: mutedBg, fg: mutedFg),
            ], buttonHeight),

            _buildRow([
              _CalcButtonData(
                '=',
                bg: equalsBg,
                fg: equalsFg,
                onTap: _calculate,
                flex: 4,
              ),
            ], buttonHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<_CalcButtonData> buttons, double height) {
    return Row(
      children: buttons
          .map(
            (b) => Expanded(
              flex: b.flex,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Material(
                  color: b.bg,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: b.onTap ?? () => _append(b.text),
                    child: Container(
                      height: height,
                      alignment: Alignment.center,
                      child: Text(
                        b.text,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: b.fg,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalcButtonData {
  final String text;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final int flex;

  _CalcButtonData(
    this.text, {
    required this.bg,
    required this.fg,
    this.onTap,
    this.flex = 1,
  });
}
