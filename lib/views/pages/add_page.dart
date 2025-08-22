import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:spendle/database/Logic/add_expense.dart';
import 'package:spendle/database/models/category.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Category? selectedCategory;

  @override
  void initState() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    super.initState();
  }

  @override
  void dispose() {
    expenseController.dispose();
    dateController.dispose();
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
                Lottie.asset('assets/lotties/wallet.json', height: 300),
                const Text(
                  "Add Expenses",
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
                    // prefix: Text('\$ '),
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
                  onTap: () async {
                    DateTime? setDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 10)),
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
                    onPressed: () {
                      // Category check
                      if (selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a category'),
                          ),
                        );
                        return;
                      }

                      // Date
                      final date = selectedDate;

                      // Amount check
                      final amount = double.tryParse(expenseController.text);
                      if (amount == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid amount')),
                        );
                        return;
                      }

                      // Insert into DB
                      addExpense(
                        category: selectedCategory!.name,
                        amount: amount,
                        date: date,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense saved!')),
                      );

                      Navigator.pop(context);

                      // Clear fields
                      setState(() {
                        selectedCategory = null;
                      });
                      expenseController.clear();
                      dateController.clear();
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
