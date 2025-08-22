import 'package:flutter/material.dart';

class CurvedboxWidget extends StatelessWidget {
  const CurvedboxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.elliptical(300, 30), // round top-left
        bottomLeft: Radius.elliptical(300, 30),
      ),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
            transform: const GradientRotation(3.1416 / 4),
          ),
        ),
      ),
    );
  }
}

class CurvedboxWidget2 extends StatelessWidget {
  const CurvedboxWidget2({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.elliptical(300, 30), // round top-left
        bottomLeft: Radius.elliptical(300, 30),
      ),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }
}

class CurvedboxWidget3 extends StatelessWidget {
  const CurvedboxWidget3({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.elliptical(300, 30), // round top-left
        bottomLeft: Radius.elliptical(300, 30),
      ),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }
}
