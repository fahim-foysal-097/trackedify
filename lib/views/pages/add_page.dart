import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/Logic/add_expense.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/views/pages/calculator.dart';
import 'package:spendle/views/pages/create_category_page.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  String? selectedCategoryName;
  List<Map<String, dynamic>> categories = [];

  // -------- Tips --------
  bool showTips = false;
  List<String> tips = [
    "You can create your own categories!",
    "Long press a category to delete it.",
    "Tap a category to select it.",
  ];

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    loadCategories();
    checkShowTips();
  }

  Future<void> checkShowTips() async {
    final db = await DatabaseHelper().database;
    final res = await db.query("user_info", limit: 1);
    if (res.isEmpty) {
      // create a default user row if none exists
      await db.insert("user_info", {"username": "User"});
      setState(() => showTips = true);
      return;
    }
    final row = res.first;
    if ((row["add_tip_shown"] ?? 0) == 0) {
      setState(() => showTips = true);
      await db.update("user_info", {"add_tip_shown": 1});
    }
  }

  Future<void> loadCategories() async {
    final dbCategories = await DatabaseHelper().getCategories();
    setState(() {
      categories = dbCategories.map((cat) {
        return {
          'id': cat['id'],
          'name': cat['name'],
          'color': Color(cat['color']),
          'icon': IconData(cat['icon_code'], fontFamily: 'MaterialIcons'),
        };
      }).toList();

      if (selectedCategoryName != null &&
          !categories.any((c) => c['name'] == selectedCategoryName)) {
        selectedCategoryName = null;
      }
    });
  }

  Future<void> addCustomCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCategoryPage()),
    );

    // refresh categories if a category was added
    if (result == true) {
      await loadCategories();
    }
  }

  Future<void> deleteCategory(int id, String name) async {
    final confirm = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete Category?",
      message: 'Are you sure you want to delete "$name"?',
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () {
        Navigator.pop(context, false);
      },
      onTapConfirm: () {
        Navigator.pop(context, true);
      },
      textColor: Colors.grey.shade700,
      panaraDialogType: PanaraDialogType.error,
    );

    if (confirm == true) {
      final db = await DatabaseHelper().database;
      await db.delete("categories", where: "id = ?", whereArgs: [id]);
      await loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Category '$name' deleted!")));
    }
  }

  Map<String, dynamic>? getSelectedCategory() {
    if (selectedCategoryName == null) return null;
    try {
      return categories.firstWhere((c) => c['name'] == selectedCategoryName);
    } catch (e) {
      return null;
    }
  }

  void _showCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExpenseCalculator(
        onResult: (value) {
          expenseController.text = value.toStringAsFixed(2);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    expenseController.dispose();
    dateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(backgroundColor: Colors.grey.shade200),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset('assets/lotties/wallet.json', height: 270),
                const Text(
                  "Add Expenses",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // ------------------ TIPS ------------------
                if (showTips && tips.isNotEmpty)
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tips.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final tip = tips[index];
                        return SizedBox(
                          width: 300,
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb,
                                      color: Color(0xFF6C5CE7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() => tips.removeAt(index));
                                      if (tips.isEmpty) {
                                        setState(() => showTips = false);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 30),

                // ------------------ CATEGORY SELECTOR ------------------
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1, // +1 for Add button
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Add Category button
                        return GestureDetector(
                          onTap: addCustomCategory,
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.amber,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.amber,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Add",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final cat = categories[index - 1]; // shift by -1
                      final isSelected = cat['name'] == selectedCategoryName;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryName = cat['name'];
                          });
                        },
                        onLongPress: () =>
                            deleteCategory(cat['id'], cat['name']),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: cat['color'],
                              radius: isSelected ? 25 : 24,
                              child: Icon(
                                cat['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['name'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Amount field & Calculator
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expenseController,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: "Amount",
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            FontAwesomeIcons.moneyCheckDollar,
                            size: 18,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _showCalculator,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                            horizontal: 17,
                          ),
                          child: const Icon(
                            Icons.calculate,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date field
                TextField(
                  controller: dateController,
                  textAlignVertical: TextAlignVertical.center,
                  readOnly: true,
                  onTap: () async {
                    DateTime? setDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1095),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 700)),
                    );
                    if (setDate != null) {
                      dateController.text = DateFormat(
                        'dd/MM/yyyy',
                      ).format(setDate);
                      selectedDate = setDate;
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Date",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.solidClock,
                      size: 18,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Note Field
                TextField(
                  controller: noteController,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Add a note",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.solidNoteSticky,
                      size: 18,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: kToolbarHeight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (selectedCategoryName == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a category'),
                          ),
                        );
                        return;
                      }
                      final category = getSelectedCategory();
                      if (category == null) return;

                      final amount = double.tryParse(expenseController.text);
                      if (amount == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an amount'),
                          ),
                        );
                        return;
                      }

                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid amount')),
                        );
                        return;
                      }

                      final noteText = noteController.text.trim();

                      addExpense(
                        category: category['name'],
                        amount: amount,
                        date: selectedDate,
                        note: noteText,
                      );

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   const SnackBar(content: Text('Expense saved!')),
                      // );

                      if (kDebugMode) {
                        debugPrint('Expense saved!');
                      }

                      Navigator.pop(context);
                      setState(() => selectedCategoryName = null);
                      expenseController.clear();
                      dateController.clear();
                      noteController.clear();
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension ColorHex on Color {
  int toARGB32() {
    final alphaValue = (a * 255.0).round() & 0xff;
    final redValue = (r * 255.0).round() & 0xff;
    final greenValue = (g * 255.0).round() & 0xff;
    final blueValue = (b * 255.0).round() & 0xff;
    return (alphaValue << 24) |
        (redValue << 16) |
        (greenValue << 8) |
        blueValue;
  }
}
