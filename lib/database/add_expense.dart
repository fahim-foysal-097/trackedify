import 'package:trackedify/database/database_helper.dart';

Future<int> addExpense({
  required int categoryId,
  required double amount,
  required DateTime date,
  required String note,
}) async {
  final formattedDate = date.toIso8601String().split('T').first;

  return DatabaseHelper().insertExpense(
    categoryId: categoryId,
    amount: amount,
    date: formattedDate,
    note: note,
  );
}
