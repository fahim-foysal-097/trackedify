import 'package:spendle/database/database_helper.dart';

Future<void> addExpense({
  required String category,
  required double amount,
  required DateTime date,
  required String note,
}) async {
  final db = await DatabaseHelper().database;

  final formattedDate = date.toIso8601String().split('T').first;

  await db.insert('expenses', {
    'category': category,
    'amount': amount,
    'date': formattedDate,
    'note': note,
  });
}
