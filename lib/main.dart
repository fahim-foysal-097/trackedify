import 'package:flutter/material.dart';
import 'package:spendle/services/auth_gate.dart';
import 'package:spendle/views/pages/set_pin_page.dart';
import 'package:spendle/views/widget_tree.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          primary: const Color(0xFF00b4d8),
          secondary: const Color(0xFF56CCF2),
          tertiary: const Color(0xFF2F80ED),
          brightness: Brightness.light,
          surface: Colors.grey.shade100,
        ),
      ),
      routes: {'/set-pin': (context) => const SetPinPage()},
      home: const AuthGate(child: WidgetTree()),
    );
  }
}
