import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'edit_expense_page.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  List<Map<String, dynamic>> expenses = [];
  bool showTip = false;
  Map<String, Map<String, dynamic>> categoryMap = {}; // name -> {color, icon}

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadExpenses();
  }

  Future<void> loadCategories() async {
    final dbCategories = await DatabaseHelper().getCategories();
    setState(() {
      categoryMap = {
        for (var cat in dbCategories)
          cat['name']: {
            'color': Color(cat['color']),
            'icon': IconData(cat['icon_code'], fontFamily: 'MaterialIcons'),
          },
      };
    });
  }

  Future<void> checkTips() async {
    if (expenses.isEmpty) return; // Do not show tip if no data

    final db = await DatabaseHelper().database;
    final result = await db.query('user_info', limit: 1);

    if (result.isEmpty) {
      await db.insert('user_info', {
        'username': 'User',
        'history_tip_shown': 0,
      });
    }

    final row = (await db.query('user_info', limit: 1)).first;
    final tipsShown = row['history_tip_shown'] ?? 0;

    if (tipsShown == 0) {
      setState(() {
        showTip = true;
      });
      await db.update(
        'user_info',
        {'history_tip_shown': 1},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final data = await db.query('expenses', orderBy: 'date DESC');
    setState(() {
      expenses = data;
    });
    await checkTips();
  }

  Map<String, dynamic> getCategory(String name) {
    return categoryMap[name] ?? {'color': Colors.grey, 'icon': Icons.category};
  }

  Future<void> deleteExpense(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await loadExpenses();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
    }
  }

  void confirmDelete(Map<String, dynamic> expense) {
    if (showTip) setState(() => showTip = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense?'),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void openEdit(Map<String, dynamic> expense) {
    if (showTip) setState(() => showTip = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditExpensePage(expense: expense)),
    ).then((_) => loadExpenses());
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
              itemCount: expenses.length + (showTip ? 1 : 0),
              itemBuilder: (context, index) {
                if (showTip && index == 1) {
                  // Show tip below the first expense
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => showTip = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Tip: Swipe left to edit,\n swipe right to delete!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  );
                }

                final adjustedIndex = showTip && index > 1 ? index - 1 : index;
                final expense = expenses[adjustedIndex];
                final cat = getCategory(expense['category']);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Dismissible(
                    key: Key(expense['id'].toString()),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Swipe right → delete
                        confirmDelete(expense);
                        return false; // Don't auto-remove from list
                      } else if (direction == DismissDirection.endToStart) {
                        // Swipe left → edit
                        openEdit(expense);
                        return false;
                      }
                      return false;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cat['color'],
                          child: Icon(cat['icon'], color: Colors.white),
                        ),
                        title: Text(
                          expense['category'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          expense['date'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          "-\$${expense['amount'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
