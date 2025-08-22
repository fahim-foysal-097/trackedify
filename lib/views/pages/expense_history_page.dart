import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/database/models/category.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final data = await db.query('expenses', orderBy: 'date DESC');
    setState(() {
      expenses = data;
    });
  }

  Category getCategory(String name) {
    return categories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => categories[0],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await loadExpenses();

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Expense History",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: expenses.isEmpty
          ? const Center(
              child: Text(
                'No expenses to show',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final cat = getCategory(expense['category']);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cat.color,
                        child: Icon(cat.icon, color: Colors.white),
                      ),
                      title: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        expense['date'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "-\$${expense['amount'].toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              // Confirm deletion
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Expense?'),
                                  content: const Text(
                                    'Are you sure you want to delete this expense?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        deleteExpense(expense['id']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
