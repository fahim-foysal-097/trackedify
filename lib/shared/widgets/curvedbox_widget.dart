import 'package:flutter/material.dart';
import 'package:trackedify/services/theme_controller.dart';

class CurvedboxWidget extends StatelessWidget {
  const CurvedboxWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = ThemeController.instance;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomRight: Radius.elliptical(300, 30),
        bottomLeft: Radius.elliptical(300, 30),
      ),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ctrl.effectiveColorForRole(context, 'curvedbox-1'),
              ctrl.effectiveColorForRole(context, 'curvedbox-2'),
              ctrl.effectiveColorForRole(context, 'curvedbox-3'),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            transform: const GradientRotation(3.1416 / 4),
          ),
        ),
      ),
    );
  }
}
