import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/database/models/category.dart';
import 'edit_expense_page.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> expenses = [];
  bool showTip = false;

  late AnimationController _controller;
  late Animation<Offset> _wiggleAnimation;

  @override
  void initState() {
    super.initState();
    initAnimation();
    loadExpenses();
  }

  void initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _wiggleAnimation = Tween<Offset>(
      begin: const Offset(-0.02, 0),
      end: const Offset(0.02, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  Future<void> checkTips() async {
    if (expenses.isEmpty) return; // Do not show tip if no data

    final db = await DatabaseHelper().database;
    final result = await db.query('user_info', limit: 1);

    if (result.isEmpty) {
      // Insert default user row if none exists
      await db.insert('user_info', {'username': 'User', 'tips_shown': 0});
    }

    final row = (await db.query('user_info', limit: 1)).first;
    final tipsShown = row['tips_shown'] ?? 0;

    if (tipsShown == 0) {
      setState(() {
        showTip = true;
      });
      // Update tips_shown to 1 so it never shows again
      await db.update(
        'user_info',
        {'tips_shown': 1},
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
    await checkTips(); // check tips after loading data
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

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
    }
  }

  void confirmDelete(Map<String, dynamic> expense) {
    if (showTip) {
      setState(() {
        showTip = false;
      });
    }

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
    if (showTip) {
      setState(() {
        showTip = false;
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditExpensePage(expense: expense)),
    ).then((_) => loadExpenses());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      body: Stack(
        children: [
          expenses.isEmpty
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
                      child: GestureDetector(
                        onTap: () => openEdit(expense),
                        onLongPress: () => confirmDelete(expense),
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
          if (showTip && expenses.isNotEmpty)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _wiggleAnimation,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Tip: Tap to edit, long press to delete!",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomPaint(
                      size: const Size(20, 10),
                      painter: _TrianglePainter(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueAccent;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
