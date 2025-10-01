import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:spendle/database/database_helper.dart';

class EditExpensePage extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController =
      TextEditingController(); // <- added
  DateTime selectedDate = DateTime.now();

  String? selectedCategoryName;
  Map<String, Map<String, dynamic>> categoryMap = {}; // name -> {color, icon}

  final DateFormat displayFormat = DateFormat('dd/MM/yyyy');
  final DateFormat dbFormat = DateFormat('yyyy-MM-dd');

  // same icon options as AddPage (expanded)
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

    // init controllers with expense values
    expenseController.text = widget.expense['amount'].toString();

    noteController.text = (widget.expense['note'] ?? '') as String;

    try {
      // try parsing date; expense['date'] expected as ISO / yyyy-MM-dd string
      selectedDate = DateTime.parse(widget.expense['date'] as String);
    } catch (_) {
      selectedDate = DateTime.now();
    }
    dateController.text = displayFormat.format(selectedDate);

    selectedCategoryName = widget.expense['category'] as String?;

    loadCategories();
  }

  Future<void> loadCategories() async {
    final db = await DatabaseHelper().database;
    final dbCategories = await db.query('categories');
    setState(() {
      categoryMap = {
        for (var cat in dbCategories)
          (cat['name'] as String): {
            'color': Color(cat['color'] as int),
            'icon': IconData(
              cat['icon_code'] as int,
              fontFamily: 'MaterialIcons',
            ),
          },
      };

      // ensure selectedCategoryName is valid
      if (selectedCategoryName == null && categoryMap.isNotEmpty) {
        selectedCategoryName = categoryMap.keys.first;
      } else if (selectedCategoryName != null &&
          !categoryMap.containsKey(selectedCategoryName)) {
        // fallback to first if it's gone
        selectedCategoryName = categoryMap.isNotEmpty
            ? categoryMap.keys.first
            : null;
      }
    });
  }

  Map<String, dynamic> getSelectedCategory() {
    if (selectedCategoryName == null) {
      return {'color': Colors.grey, 'icon': Icons.category};
    }
    return categoryMap[selectedCategoryName!] ??
        {'color': Colors.grey, 'icon': Icons.category};
  }

  Future<void> saveChanges() async {
    if (selectedCategoryName == null) {
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

    await db.update(
      'expenses',
      {
        'amount': amount,
        'category': selectedCategoryName,
        // store as yyyy-MM-dd to avoid timezone surprises
        'date': dbFormat.format(selectedDate),
        'note': noteController.text.trim(),
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
      lastDate: DateTime.now().add(const Duration(days: 700)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = displayFormat.format(picked);
      });
    }
  }

  // --- Add category dialog (icon grid + color picker) ---
  Future<void> addCategoryDialog() async {
    String name = '';
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.more_horiz;
    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('New Category'),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: "Category Name"),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Pick Icon"),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconOptions.map((icon) {
                    final isSel = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          selectedIcon = icon;
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: isSel
                            ? Colors.blue
                            : Colors.grey.withAlpha(220),
                        child: Icon(icon, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Pick Color"),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    Color pickedColor = selectedColor;
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Select Color'),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.all(
                            Radius.circular(10),
                          ),
                        ),
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
      final db = await DatabaseHelper().database;
      await db.insert('categories', {
        'name': name,
        'color': selectedColor.toARGB32(),
        'icon_code': selectedIcon.codePoint,
      });
      await loadCategories();
      // select the newly created category
      setState(() {
        selectedCategoryName = name;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category "$name" added!')));
    }
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
                Lottie.asset('assets/lotties/wallet.json', height: 300),
                const Text(
                  "Edit Expense",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),

                // Category dropdown + add button (keeps your styling)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        menuMaxHeight: 400,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
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
                        initialValue: selectedCategoryName,
                        items: categoryMap.keys.map((name) {
                          final cat = categoryMap[name]!;
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: cat['color'] as Color,
                                  radius: 14,
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (name) {
                          setState(() {
                            selectedCategoryName = name;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: addCategoryDialog,
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                    ),
                  ],
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
