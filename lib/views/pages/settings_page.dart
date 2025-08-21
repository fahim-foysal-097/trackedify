// import 'package:flutter/material.dart';
// import 'package:spendle/database/database_helper.dart';

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});

//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage> {
//   String currentName = "User Name";

//   Future<void> loadExpenses() async {
//     final db = await DatabaseHelper().database;
//     final data = await db.query('user_info', limit: 1);
//     setState(() {
//       currentName = data.first['username'] as String;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Settings",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//         ),
//         centerTitle: true,
//       ),
//       body: Text(currentName),
//     );
//   }
// }
