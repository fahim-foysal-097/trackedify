import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:spendle/database/Logic/add_expense.dart';
import 'package:spendle/database/database_helper.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  String? selectedCategoryName;
  List<Map<String, dynamic>> categories = [];

  // -------- Tips --------
  bool showTips = false;
  List<String> tips = [
    "💡 Tip: You can create your own categories!",
    "💡 Tip: Long press a category to delete it.",
    "💡 Tip: Tap a category to select it.",
  ];

  final List<IconData> iconOptions = [
    Icons.fastfood,
    Icons.directions_bus,
    Icons.shopping_cart,
    Icons.movie_outlined,
    Icons.videogame_asset,
    Icons.lightbulb_outline,
    Icons.health_and_safety,
    Icons.school_outlined,
    Icons.local_grocery_store,
    Icons.flight_takeoff,
    Icons.local_gas_station,
    Icons.subscriptions,
    Icons.card_giftcard,
    Icons.sports_soccer,
    Icons.pets,
    Icons.account_balance,
    Icons.home_outlined,
    Icons.trending_up,
    Icons.power,
    Icons.security,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.local_pharmacy,
    Icons.sports_basketball,
    Icons.book,
    Icons.music_note,
    Icons.camera_alt,
    Icons.phone_android,
    Icons.computer,
    Icons.more_horiz,
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
    String name = '';
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.more_horiz;
    TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('New Category'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Category Name",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Pick Icon"),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconOptions.map((icon) {
                    return GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          selectedIcon = icon;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: selectedIcon == icon
                            ? Colors.blue
                            : Colors.grey[300],
                        child: Icon(icon, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text("Pick Color"),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    Color pickedColor = selectedColor;
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Select Color'),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: selectedColor,
                            onColorChanged: (color) => pickedColor = color,
                            enableAlpha: false,
                            displayThumbColor: true,
                            pickerAreaHeightPercent: 0.8,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setStateDialog(() {
                                selectedColor = pickedColor;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: selectedColor,
                    radius: 24,
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                name = nameController.text.trim();
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (name.isNotEmpty) {
      await DatabaseHelper().addCategory(
        name,
        selectedColor.toARGB32(),
        selectedIcon.codePoint,
      );
      await loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category "$name" added!')));
    }
  }

  Future<void> deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
                const SizedBox(height: 20),

                // ------------------ TIPS ------------------
                if (showTips && tips.isNotEmpty)
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onLongPress: () {
                            setState(() => tips.removeAt(index));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent),
                            ),
                            child: Center(
                              child: Text(
                                tips[index],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
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
                              radius: 24,
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

                // Amount field
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
                          const SnackBar(content: Text('Invalid amount')),
                        );
                        return;
                      }

                      addExpense(
                        category: category['name'],
                        amount: amount,
                        date: selectedDate,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense saved!')),
                      );

                      Navigator.pop(context);
                      setState(() => selectedCategoryName = null);
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
