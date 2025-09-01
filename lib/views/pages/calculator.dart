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

      // Handle percentages
      exp = exp.replaceAllMapped(RegExp(r'(\d+(\.\d+)?)%'), (match) {
        final val = double.parse(match.group(1)!);
        return (val / 100).toString();
      });

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

  Widget _buildButton(
    String text, {
    Color bgColor = Colors.grey,
    Color textColor = Colors.black,
    Function()? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap ?? () => _append(text),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
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
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1),
            Column(
              children: [
                Row(
                  children: [
                    _buildButton(
                      'C',
                      bgColor: Colors.redAccent,
                      textColor: Colors.white,
                      onTap: _clear,
                    ),
                    _buildButton(
                      '⌫',
                      bgColor: Colors.orange,
                      textColor: Colors.white,
                      onTap: _delete,
                    ),
                    _buildButton(
                      '%',
                      bgColor: Colors.blueAccent,
                      textColor: Colors.white,
                      onTap: () {
                        if (_expression.isNotEmpty) {
                          _append('%');
                          _calculate();
                        }
                      },
                    ),
                    _buildButton(
                      '÷',
                      bgColor: Colors.blueAccent,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('7', bgColor: Colors.white),
                    _buildButton('8', bgColor: Colors.white),
                    _buildButton('9', bgColor: Colors.white),
                    _buildButton(
                      '×',
                      bgColor: Colors.blueAccent,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('4', bgColor: Colors.white),
                    _buildButton('5', bgColor: Colors.white),
                    _buildButton('6', bgColor: Colors.white),
                    _buildButton(
                      '-',
                      bgColor: Colors.blueAccent,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('1', bgColor: Colors.white),
                    _buildButton('2', bgColor: Colors.white),
                    _buildButton('3', bgColor: Colors.white),
                    _buildButton(
                      '+',
                      bgColor: Colors.blueAccent,
                      textColor: Colors.white,
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildButton('(', bgColor: Colors.grey.shade200),
                    _buildButton('0', bgColor: Colors.white),
                    _buildButton('.', bgColor: Colors.white),
                    _buildButton(')', bgColor: Colors.grey.shade200),
                  ],
                ),
                Row(
                  children: [
                    _buildButton(
                      '=',
                      bgColor: Colors.green,
                      textColor: Colors.white,
                      onTap: _calculate,
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
