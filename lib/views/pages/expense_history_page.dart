import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spendle/database/database_helper.dart';
import 'edit_expense_page.dart';

class ExpenseHistoryPage extends StatefulWidget {
  const ExpenseHistoryPage({super.key});

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];
  bool showTip = false;
  Map<String, Map<String, dynamic>> categoryMap = {}; // name -> {color, icon}
  final TextEditingController _searchController = TextEditingController();

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
    if (expenses.isEmpty) return;

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
      filteredExpenses = data;
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

  void filterExpenses(String query) {
    if (query.isEmpty) {
      setState(() => filteredExpenses = expenses);
      return;
    }

    query = query.toLowerCase();
    setState(() {
      filteredExpenses = expenses.where((expense) {
        final category = (expense['category'] ?? '').toString().toLowerCase();
        final amount = (expense['amount'] ?? '').toString().toLowerCase();
        final date = (expense['date'] ?? '').toString().toLowerCase();
        final note = (expense['note'] ?? '').toString().toLowerCase();

        return category.contains(query) ||
            amount.contains(query) ||
            date.contains(query) ||
            note.contains(query);
      }).toList();
    });
  }

  void _showFullNoteDialog(String? note) {
    final isEmpty = note == null || note.trim().isEmpty;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: isEmpty ? const Text("No note to show") : Text(note),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Expense History",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: filterExpenses,
                decoration: InputDecoration(
                  hintText: "Search by category, amount, date or note",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: filteredExpenses.isEmpty
            ? const Center(
                child: Text(
                  'No expenses to show',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                itemCount: filteredExpenses.length + (showTip ? 1 : 0),
                itemBuilder: (context, index) {
                  if (showTip && index == 1) {
                    // Tip in "callout" style
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        color: Colors.lightBlue.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.lightbulb,
                            color: Colors.blue,
                          ),
                          title: const Text(
                            "Tip: Swipe left to delete, swipe right to edit and tap to view note!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => setState(() => showTip = false),
                          ),
                        ),
                      ),
                    );
                  }

                  final adjustedIndex = showTip && index > 1
                      ? index - 1
                      : index;
                  final expense = filteredExpenses[adjustedIndex];
                  final cat = getCategory(expense['category'] ?? '');

                  final noteText = (expense['note'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Dismissible(
                      key: Key(expense['id'].toString()),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.edit, color: Colors.white),
                            SizedBox(width: 10),
                            Text("Edit", style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Delete",
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.delete, color: Colors.white),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          openEdit(expense);
                          return false;
                        } else if (direction == DismissDirection.endToStart) {
                          confirmDelete(expense);
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
                          onTap: () {
                            _showFullNoteDialog(noteText);
                          },
                          leading: CircleAvatar(
                            backgroundColor: cat['color'],
                            child: Icon(cat['icon'], color: Colors.white),
                          ),
                          title: Text(
                            expense['category'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['date'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (noteText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _showFullNoteDialog(noteText),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.solidNoteSticky,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          noteText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Text(
                            "-\$${(expense['amount'] is num) ? (expense['amount'] as num).toDouble().toStringAsFixed(2) : double.tryParse(expense['amount'].toString())?.toStringAsFixed(2) ?? expense['amount'].toString()}",
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
      ),
    );
  }
}
