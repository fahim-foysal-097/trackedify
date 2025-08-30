import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/database/models/category.dart';

class EditExpensePage extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Category? selectedCategory;

  final DateFormat displayFormat = DateFormat('dd/MM/yyyy');
  final DateFormat dbFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();

    expenseController.text = widget.expense['amount'].toString();

    // Parse date from DB correctly
    try {
      selectedDate = DateTime.parse(widget.expense['date']);
    } catch (_) {
      selectedDate = DateTime.now();
    }
    dateController.text = displayFormat.format(selectedDate);

    selectedCategory = categories.firstWhere(
      (cat) => cat.name == widget.expense['category'],
      orElse: () => categories[0],
    );
  }

  @override
  void dispose() {
    expenseController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final amount = double.tryParse(expenseController.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    final db = await DatabaseHelper().database;

    // Store date in 'yyyy-MM-dd' format to avoid timezone issues
    await db.update(
      'expenses',
      {
        'amount': amount,
        'category': selectedCategory!.name,
        'date': dbFormat.format(selectedDate),
      },
      where: 'id = ?',
      whereArgs: [widget.expense['id']],
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Expense updated')));
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1095)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = displayFormat.format(picked);
      });
    }
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
                Lottie.asset('assets/lotties/wallet.json', height: 300),
                const Text(
                  "Edit Expense",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 50),
                DropdownButtonFormField<Category>(
                  menuMaxHeight: 400,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  decoration: InputDecoration(
                    hintText: "Category",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.list,
                      size: 18,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  initialValue: selectedCategory,
                  items: categories.map((cat) {
                    return DropdownMenuItem<Category>(
                      value: cat,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: cat.color,
                            radius: 14,
                            child: Icon(
                              cat.icon,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextField(
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
                      FontAwesomeIcons.dollarSign,
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
                TextField(
                  controller: dateController,
                  textAlignVertical: TextAlignVertical.center,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: InputDecoration(
                    hintText: "Date",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.clock,
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
                    onPressed: saveChanges,
                    child: const Text(
                      "Save Changes",
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
