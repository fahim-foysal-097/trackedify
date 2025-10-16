import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ColorScheme defaultLight = ColorScheme.fromSeed(
  brightness: Brightness.light,
  seedColor: Colors.indigoAccent,
  primary: Colors.deepPurple,
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: Colors.blueAccent.shade400,
  secondary: const Color(0xFF56CCF2),
  tertiary: const Color(0xFF2F80ED),
  surface: Colors.grey.shade100,
  error: Colors.red,
  onError: Colors.white,
);

ColorScheme defaultDark = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: Colors.indigoAccent,
  primary: Colors.deepPurple,
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: Colors.blue.shade700,
  secondary: const Color(0xFF56CCF2),
  tertiary: const Color(0xFF2F80ED),
  surface: const Color.fromARGB(255, 14, 14, 14),
  error: Colors.red,
  onError: Colors.white,
);

final List<FlexScheme> curatedBuiltInSchemes = [
  FlexScheme.flutterDash,
  FlexScheme.mandyRed,
  FlexScheme.deepBlue,
  FlexScheme.aquaBlue,
  FlexScheme.hippieBlue,
  FlexScheme.amber,
  FlexScheme.red,
  FlexScheme.bigStone,
  FlexScheme.deepPurple,
  FlexScheme.shadBlue,
  FlexScheme.cyanM3,
  FlexScheme.green,
  FlexScheme.deepOrangeM3,
  FlexScheme.blueM3,
  FlexScheme.materialBaseline,
];
