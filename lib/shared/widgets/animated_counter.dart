import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final int decimalDigits;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimalDigits = 2,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animValue, child) {
        final formattedValue = animValue.toStringAsFixed(decimalDigits);
        return Text('$prefix$formattedValue$suffix', style: style);
      },
    );
  }
}
