import 'package:flutter/material.dart';

class CurvedboxWidget extends StatelessWidget {
  const CurvedboxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.elliptical(300, 30),
        bottomLeft: Radius.elliptical(300, 30),
      ),
      child: Container(
        height: 350,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 37, 140, 214),
              Color.fromARGB(255, 37, 120, 214),
              Color.fromARGB(255, 35, 90, 209),
            ],
            transform: GradientRotation(3.1416 / 4),
          ),
        ),
      ),
    );
  }
}
