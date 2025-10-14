import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class ExpenseCalculator extends StatefulWidget {
  final Function(double) onResult;

  const ExpenseCalculator({super.key, required this.onResult});

  @override
  State<ExpenseCalculator> createState() => _ExpenseCalculatorState();
}

class _ExpenseCalculatorState extends State<ExpenseCalculator> {
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
    try {
      if (_expression.isEmpty) return;

      String exp = _expression.replaceAll('×', '*').replaceAll('÷', '/');

      // Handle simple percentages for expressions like 100 + 20% or 100 - 20%
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

      // Handle standalone percentages like 20%
      exp = exp.replaceAllMapped(
        RegExp(r'(\d+(\.\d+)?)%'),
        (match) => '(${match.group(1)!}/100)',
      );

      ShuntingYardParser p = ShuntingYardParser();
      Expression expression = p.parse(exp);
      ContextModel cm = ContextModel();
      RealEvaluator evaluator = RealEvaluator(cm);
      double eval = evaluator.evaluate(expression) as double;

      // Prevent negative results
      if (eval.isNaN || eval.isInfinite || eval < 0) {
        setState(() {
          _result = 'Error';
          _expression = '';
        });
        return;
      }

      setState(() {
        _result = eval.toStringAsFixed(2);
        _expression = _result; // for chained calculations
      });

      widget.onResult(eval);
    } catch (e) {
      setState(() {
        _result = 'Error';
        _expression = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme-aware colors
    final ColorScheme cs = Theme.of(context).colorScheme;

    // Primary operator color (uses primary)
    final Color opBg = cs.primary;
    final Color opText = cs.onPrimary;

    // Accent for "=" button
    final Color equalsBg = cs.secondary;
    final Color equalsText = cs.onSecondary;

    // Danger / clear
    final Color clearBg = cs.error;
    final Color clearText = cs.onError;

    // Backspace - use tertiary or fallback to orange-like
    final Color backBg = (cs.tertiary != Colors.transparent)
        ? cs.tertiary
        : Colors.orange;
    final Color backText = cs.onTertiary;

    // Number button background & text
    final Color numberBg = cs.surface;
    final Color numberText = cs.onSurface;

    // Bracket / dot buttons slightly muted
    final Color mutedBg = cs.surfaceContainer;
    final Color mutedText = cs.onSurfaceVariant;

    // Container background
    final Color containerBg = cs.surface;

    // Divider color
    final Color dividerColor = cs.onSurface.withValues(alpha: 0.12);

    // Button height adapt to width (small responsiveness)
    final width = MediaQuery.of(context).size.width;
    final buttonHeight = width > 420 ? 70.0 : 60.0;

    Widget themedButton(
      String text, {
      required Color bg,
      required Color fg,
      Function()? onTap,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap ?? () => _append(text),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: buttonHeight,
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression.isEmpty ? '0' : _expression,
                    style: TextStyle(
                      fontSize: 20,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _result,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(thickness: 1, color: dividerColor),
            Column(
              children: [
                Row(
                  children: [
                    // Clear
                    themedButton(
                      'C',
                      bg: clearBg,
                      fg: clearText,
                      onTap: _clear,
                    ),
                    // Backspace
                    themedButton('⌫', bg: backBg, fg: backText, onTap: _delete),
                    // Percent
                    themedButton(
                      '%',
                      bg: opBg,
                      fg: opText,
                      onTap: () {
                        if (_expression.isNotEmpty) {
                          _append('%');
                          _calculate();
                        }
                      },
                    ),
                    // Divide
                    themedButton('÷', bg: opBg, fg: opText),
                  ],
                ),
                Row(
                  children: [
                    themedButton('7', bg: numberBg, fg: numberText),
                    themedButton('8', bg: numberBg, fg: numberText),
                    themedButton('9', bg: numberBg, fg: numberText),
                    themedButton('×', bg: opBg, fg: opText),
                  ],
                ),
                Row(
                  children: [
                    themedButton('4', bg: numberBg, fg: numberText),
                    themedButton('5', bg: numberBg, fg: numberText),
                    themedButton('6', bg: numberBg, fg: numberText),
                    themedButton('-', bg: opBg, fg: opText),
                  ],
                ),
                Row(
                  children: [
                    themedButton('1', bg: numberBg, fg: numberText),
                    themedButton('2', bg: numberBg, fg: numberText),
                    themedButton('3', bg: numberBg, fg: numberText),
                    themedButton('+', bg: opBg, fg: opText),
                  ],
                ),
                Row(
                  children: [
                    themedButton('(', bg: mutedBg, fg: mutedText),
                    themedButton('0', bg: numberBg, fg: numberText),
                    themedButton('.', bg: numberBg, fg: numberText),
                    themedButton(')', bg: mutedBg, fg: mutedText),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Material(
                          color: equalsBg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _calculate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: buttonHeight,
                              alignment: Alignment.center,
                              child: Text(
                                '=',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: equalsText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
