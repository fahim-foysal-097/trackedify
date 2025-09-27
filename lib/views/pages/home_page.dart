import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/shared/widgets/curvedbox_widget.dart';
import 'package:spendle/shared/widgets/overview_widget.dart';
import 'package:spendle/shared/widgets/welcome_widget.dart';
import 'package:spendle/views/pages/add_page.dart';
import 'package:spendle/views/pages/expense_history_page.dart';
import 'edit_expense_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> expenses = [];
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

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final data = await db.query(
      'expenses',
      orderBy: 'date DESC, id DESC',
      limit: 6,
    );
    setState(() {
      expenses = data;
    });
  }

  Map<String, dynamic> getCategory(String name) {
    return categoryMap[name] ?? {'color': Colors.grey, 'icon': Icons.category};
  }

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return amount.toDouble().toStringAsFixed(2);
    }
    final parsed = double.tryParse(amount?.toString() ?? '');
    if (parsed != null) return parsed.toStringAsFixed(2);
    return amount?.toString() ?? '0.00';
  }

  Future<void> _showNoteSheet(Map<String, dynamic> expense) async {
    final note = (expense['note'] ?? '').toString();
    final hasNote = note.trim().isNotEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // meta: category / amount / date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: getCategory(
                              expense['category'] ?? '',
                            )['color'],
                            child: Icon(
                              getCategory(expense['category'] ?? '')['icon'],
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            expense['category'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "-\$${_formatAmount(expense['amount'])}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            expense['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // note content / placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasNote
                        ? Text(
                            note,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          )
                        : const Text(
                            'No note to show',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(height: 18),
                  // actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditExpensePage(expense: expense),
                              ),
                            ).then((_) {
                              // refresh after coming back from edit
                              loadCategories();
                              loadExpenses();
                            });
                          },
                          child: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        tooltip: 'Add Transaction',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
              ],
              transform: const GradientRotation(3.1416 / 4),
            ),
          ),
          child: const Icon(Icons.add),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPage()),
          ).then((_) {
            loadCategories(); // reload categories in case user added new
            loadExpenses();
          });
        },
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              const CurvedboxWidget(),
              OverviewWidget(),
              const WelcomeWidget(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Expense History',
                  style: KTextstyle.headerBlackText,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExpenseHistoryPage(),
                      ),
                    ).then((_) {
                      loadCategories();
                      loadExpenses();
                    });
                  },
                  child: const Text(
                    'Show all',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final cat = getCategory(expense['category']);
              final hasNote = (expense['note'] ?? '')
                  .toString()
                  .trim()
                  .isNotEmpty;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showNoteSheet(expense),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: cat['color'],
                                child: Icon(cat['icon'], color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                expense['category'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasNote) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  FontAwesomeIcons.solidNoteSticky,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "-\$${_formatAmount(expense['amount'])}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                expense['date'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
