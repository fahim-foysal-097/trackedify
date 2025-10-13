import 'package:flutter/material.dart';

class CurvedboxWidget extends StatelessWidget {
  const CurvedboxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.elliptical(300, 30),
        bottomLeft: Radius.elliptical(300, 30),
      ),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: const GradientRotation(3.1416 / 4),
          ),
        ),
      ),
    );
  }
}
