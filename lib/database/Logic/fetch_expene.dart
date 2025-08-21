// Not Used Anywhere

import 'package:spendle/database/database_helper.dart';

class Expense {
  final String category;
  final double amount;
  final DateTime date;

  Expense({required this.category, required this.amount, required this.date});
}

Future<List<Expense>> fetchExpenses() async {
  final db = await DatabaseHelper().database;
  final rows = await db.query('expenses', orderBy: 'date DESC');

  return rows.map((row) {
    return Expense(
      category: row['category'] as String,
      amount: row['amount'] as double,
      date: DateTime.parse(row['date'] as String),
    );
  }).toList();
}
