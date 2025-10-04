import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/views/pages/calculator.dart';
import 'package:spendle/views/pages/create_category_page.dart';

class EditExpensePage extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? selectedCategoryName;

  // categories list for grid (keeps same shape as AddPage)
  List<Map<String, dynamic>> categories = [];

  final DateFormat displayFormat = DateFormat('dd/MM/yyyy');
  final DateFormat dbFormat = DateFormat('yyyy-MM-dd');

  bool _saving = false;

  final String tips =
      '''You can edit the amount, date, category and note. Long-press a category to delete it. Use "Add" in the selector to create new categories.''';

  @override
  void initState() {
    super.initState();
    // initialize from passed expense
    expenseController.text = widget.expense['amount']?.toString() ?? '';
    noteController.text = (widget.expense['note'] ?? '') as String;

    try {
      final d = widget.expense['date'] as String?;
      if (d != null && d.isNotEmpty) {
        selectedDate = DateTime.parse(d);
      } else {
        selectedDate = DateTime.now();
      }
    } catch (_) {
      selectedDate = DateTime.now();
    }
    dateController.text = displayFormat.format(selectedDate);

    selectedCategoryName = widget.expense['category'] as String?;
    categoryController.text = selectedCategoryName ?? '';

    loadCategories();
  }

  @override
  void dispose() {
    expenseController.dispose();
    dateController.dispose();
    noteController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  Future<void> loadCategories() async {
    try {
      final dbCategories = await DatabaseHelper().getCategories();
      setState(() {
        categories = dbCategories.map((cat) {
          return {
            'id': cat['id'],
            'name': cat['name'],
            'color': Color(cat['color'] as int),
            'icon': IconData(cat['icon_code'], fontFamily: 'MaterialIcons'),
          };
        }).toList();

        // Validate selected
        if (selectedCategoryName != null &&
            !categories.any((c) => c['name'] == selectedCategoryName)) {
          // fallback to first if existing selection was removed
          selectedCategoryName = categories.isNotEmpty
              ? categories.first['name'] as String
              : null;
          categoryController.text = selectedCategoryName ?? '';
        } else if (selectedCategoryName == null && categories.isNotEmpty) {
          selectedCategoryName = categories.first['name'] as String;
          categoryController.text = selectedCategoryName ?? '';
        }
      });
    } catch (e) {
      // fallback raw query
      final db = await DatabaseHelper().database;
      final dbCategories = await db.query('categories');
      setState(() {
        categories = dbCategories.map((cat) {
          return {
            'id': cat['id'],
            'name': cat['name'],
            'color': Color(cat['color'] as int),
            'icon': IconData(
              cat['icon_code'] as int,
              fontFamily: 'MaterialIcons',
            ),
          };
        }).toList();

        if (selectedCategoryName != null &&
            !categories.any((c) => c['name'] == selectedCategoryName)) {
          selectedCategoryName = categories.isNotEmpty
              ? categories.first['name'] as String
              : null;
          categoryController.text = selectedCategoryName ?? '';
        } else if (selectedCategoryName == null && categories.isNotEmpty) {
          selectedCategoryName = categories.first['name'] as String;
          categoryController.text = selectedCategoryName ?? '';
        }
      });
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

  Future<void> addCustomCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCategoryPage()),
    );
    if (result == true) {
      await loadCategories();
    }
  }

  Future<void> deleteCategory(int id, String name) async {
    await PanaraInfoDialog.show(
      context,
      title: 'Delete Category?',
      message:
          'Long-press again to confirm deletion of "$name".\n\n(Press OK to delete.)',
      buttonText: 'Delete',
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.warning,
    );

    // PanaraInfoDialog.show returns void; to keep behavior consistent use PanaraConfirmDialog:
    // Use PanaraConfirmDialog for a real confirm flow:
    if (!mounted) return;
    final really = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete Category?",
      message: 'Are you sure you want to delete "$name"?',
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () => Navigator.pop(context, false),
      onTapConfirm: () => Navigator.pop(context, true),
      panaraDialogType: PanaraDialogType.error,
    );

    if (really == true) {
      final db = await DatabaseHelper().database;
      await db.delete("categories", where: "id = ?", whereArgs: [id]);
      await loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Category '$name' deleted!")));
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
          setState(() {}); // update preview
        },
      ),
    );
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (stateContext, modalSetState) => DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (dragContext, scrollController) => Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: Colors.white,
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(18),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    "Select Category",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width <= 600
                        ? 4
                        : 6,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
                      // Add tile (inside drawer)
                      return GestureDetector(
                        onTap: () async {
                          await addCustomCategory();
                          modalSetState(() {});
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.deepPurpleAccent,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.deepPurpleAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Add",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final cat = categories[index - 1];
                    final isSelected = cat['name'] == selectedCategoryName;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategoryName = cat['name'];
                          categoryController.text = cat['name'];
                        });
                        Navigator.pop(sheetContext);
                      },
                      onLongPress: () async {
                        await deleteCategory(cat['id'], cat['name']);
                        modalSetState(() {});
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: CircleAvatar(
                              backgroundColor: cat['color'],
                              radius: 28,
                              child: Icon(
                                cat['icon'],
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // robust label: use available width, allow up to 2 lines
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              cat['name'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
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

  Widget _buildPreviewCard() {
    final selectedCat = getSelectedCategory();
    final amountText = expenseController.text.isNotEmpty
        ? NumberFormat.currency(
            symbol: '\$',
            decimalDigits: 2,
          ).format(double.tryParse(expenseController.text) ?? 0.0)
        : '--';
    final noteText = noteController.text.trim().isEmpty
        ? 'No note'
        : noteController.text.trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBFCFF), Color(0xFFF5F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: selectedCat != null
                  ? selectedCat['color']
                  : Colors.blueGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: selectedCat != null
                ? Center(
                    child: Icon(
                      selectedCat['icon'],
                      color: Colors.white,
                      size: 28,
                    ),
                  )
                : const Center(
                    child: Icon(FontAwesomeIcons.tags, color: Colors.white38),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        selectedCategoryName ?? 'Uncategorized',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amountText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Text(
                  noteText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            color: Colors.deepPurple,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Expense preview'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _previewDialogRow(
                        'Category',
                        selectedCategoryName ?? '—',
                      ),
                      _previewDialogRow('Amount', amountText),
                      _previewDialogRow('Date', dbFormat.format(selectedDate)),
                      _previewDialogRow(
                        'Note',
                        noteText == 'No note' ? '—' : noteText,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _previewDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Future<void> saveChanges() async {
    FocusScope.of(context).unfocus();

    if (selectedCategoryName == null || selectedCategoryName!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final amount = double.tryParse(expenseController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final db = await DatabaseHelper().database;
      await db.update(
        'expenses',
        {
          'amount': amount,
          'category': selectedCategoryName,
          'date': dbFormat.format(selectedDate),
          'note': noteController.text.trim(),
        },
        where: 'id = ?',
        whereArgs: [widget.expense['id']],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Expense updated')),
            ],
          ),
        ),
      );

      if (kDebugMode) debugPrint('Expense updated');
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      if (kDebugMode) debugPrint('Failed to update expense: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update expense: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showTipsDialog() {
    PanaraInfoDialog.show(
      context,
      title: "Tips",
      message: tips.isNotEmpty ? tips : "No tips available right now.",
      buttonText: "Got it",
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = getSelectedCategory();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F8FF), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 18.0,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    // Top row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Edit Expense',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Info / tips
                        IconButton(
                          icon: const Icon(Icons.lightbulb_outlined),
                          onPressed: _showTipsDialog,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Preview card
                    _buildPreviewCard(),

                    const SizedBox(height: 8),

                    // Category selector field (opens drawer)
                    TextField(
                      controller: categoryController,
                      readOnly: true,
                      onTap: _showCategorySelector,
                      decoration: InputDecoration(
                        hintText: "Select Category",
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.grey,
                          size: 34,
                        ),
                        prefixIcon: selectedCat != null
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundColor: selectedCat['color'],
                                  radius: 14,
                                  child: Icon(
                                    selectedCat['icon'],
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              )
                            : const Icon(
                                FontAwesomeIcons.tags,
                                size: 18,
                                color: Colors.grey,
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(overflow: TextOverflow.ellipsis),
                    ),

                    const SizedBox(height: 14),

                    // Amount + calculator
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expenseController,
                            textAlignVertical: TextAlignVertical.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              hintText: "Amount",
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(
                                  FontAwesomeIcons.wallet,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _showCalculator,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 14,
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

                    const SizedBox(height: 12),

                    // Date + Today
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: dateController,
                            readOnly: true,
                            onTap: _selectDate,
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
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = DateTime.now();
                              dateController.text = displayFormat.format(
                                selectedDate,
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Note
                    TextField(
                      controller: noteController,
                      textAlignVertical: TextAlignVertical.top,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Add a note (optional)",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          FontAwesomeIcons.solidNoteSticky,
                          size: 18,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving ? null : saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
