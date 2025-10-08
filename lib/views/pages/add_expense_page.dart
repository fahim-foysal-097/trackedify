import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trackedify/database/add_expense.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/views/pages/calculator.dart';
import 'package:trackedify/views/pages/create_category_page.dart';
import 'package:trackedify/views/widget_tree.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  String? selectedCategoryName;
  List<Map<String, dynamic>> categories = [];

  // Toggle: add another after saving
  bool addAnotherAfterSave = false;

  // Loading state for save button
  bool _saving = false;

  // picked images bytes
  final List<Uint8List> _pickedImages = [];

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Image quality (1-100) to pass to platform picker. Mutable so slider can change it.
  int _selectedImageQuality = 40;

  // Single-string tips (shown every time the user taps the tips/info button)
  final String tips =
      '''You can create your own categories! Long press a category to delete it. Tap a category to select it. Attach images (optional) and choose image quality before picking.''';

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
    categoryController.text = '';
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
        categoryController.text = '';
      }
    });
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
      textColor: Colors.black54,
      panaraDialogType: PanaraDialogType.error,
    );

    if (confirm == true) {
      final db = await DatabaseHelper().database;
      await db.delete("categories", where: "id = ?", whereArgs: [id]);
      await loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Category '$name' deleted!")),
            ],
          ),
        ),
      );
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
    ).then((_) {
      NavBarController.apply();
    });
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
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == 0) {
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

                          // Robust label: use grid's available width and allow up-to-2-lines with ellipsis
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
    ).then((_) {
      NavBarController.apply();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? setDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1975),
      lastDate: DateTime(2060),
    );
    if (setDate != null) {
      setState(() {
        selectedDate = setDate;
        dateController.text = DateFormat('dd/MM/yyyy').format(setDate);
      });
    }
  }

  void _clearFields({bool keepCategory = false}) {
    setState(() {
      expenseController.clear();
      noteController.clear();
      _pickedImages.clear();
      selectedDate = DateTime.now();
      dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
      if (!keepCategory) {
        selectedCategoryName = null;
        categoryController.clear();
      }
    });
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

    // static Container — no AnimatedSwitcher (no flashing)
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
          // Category circle / placeholder
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

          // Middle content (amount & note)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Bill" header style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // handle long category names gracefully
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // eye button (no vertical stub line)
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
                      _previewDialogRow(
                        'Date',
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                      ),
                      _previewDialogRow(
                        'Note',
                        noteText == 'No note' ? '—' : noteText,
                      ),
                      if (_pickedImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Attached images:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pickedImages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () =>
                                  _viewImageFullScreen(_pickedImages[i]),
                              child: Image.memory(
                                _pickedImages[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  /// Pick multiple images (image_picker) and store bytes in _pickedImages
  Future<void> _pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: _selectedImageQuality,
      );

      if (files.isEmpty) return;

      // Show small progress modal while we read bytes
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );

      try {
        for (final f in files) {
          final bytes = await f.readAsBytes();
          if (!mounted) return;
          _pickedImages.add(bytes);
        }
      } finally {
        if (mounted) Navigator.of(context).pop();
      }

      if (mounted) setState(() {});
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Image pick failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
    }
  }

  void _removePickedImageAt(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _viewImageFullScreen(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(child: Image.memory(bytes)),
        ),
      ),
    );
  }

  /// After saving expense, persist all picked images into img_notes linking to the expense id.
  Future<void> _saveImagesForExpense(int expenseId) async {
    final dbHelper = DatabaseHelper();
    for (final bytes in _pickedImages) {
      await dbHelper.insertImageNote(
        expenseId: expenseId,
        image: bytes,
        caption: null,
      );
    }
  }

  /// Get latest expense id (most recently inserted). Relying on sequential single-user workflow.
  Future<int?> _getLatestExpenseId() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('expenses', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  Future<void> _onSavePressed() async {
    FocusScope.of(context).unfocus();

    if (selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please select a category')),
            ],
          ),
        ),
      );
      return;
    }

    final category = getSelectedCategory();
    if (category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid category')));
      return;
    }

    final amount = double.tryParse(expenseController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please enter an amount')),
            ],
          ),
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please enter a valid amount')),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final noteText = noteController.text.trim();

    try {
      await Future.sync(
        () => addExpense(
          category: category['name'],
          amount: amount,
          date: selectedDate,
          note: noteText,
        ),
      );

      // after insert, get the latest expense id (most recent)
      final expenseId = await _getLatestExpenseId();

      if (expenseId != null && _pickedImages.isNotEmpty) {
        await _saveImagesForExpense(expenseId);
      }

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
              Expanded(child: Text('Expense saved')),
            ],
          ),
        ),
      );

      if (addAnotherAfterSave) {
        _clearFields(keepCategory: true);
        setState(() => addAnotherAfterSave = false);
      } else {
        _clearFields(keepCategory: false);
        Navigator.pop(context);
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('Save error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save expense: $e')));
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
      textColor: Colors.black54,
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
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
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
                      // Top bar row
                      Row(
                        children: [
                          IconButton(
                            tooltip: "Back",
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Add Expense',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          // Tips button -> Panara dialog
                          IconButton(
                            icon: const Icon(Icons.lightbulb_outlined),
                            onPressed: _showTipsDialog,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      const SizedBox(height: 6),

                      // Live preview card (static)
                      _buildPreviewCard(),

                      const SizedBox(height: 6),

                      // Category selector
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              onChanged: (_) => setState(() {}),
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

                      // Date picker & Note
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide.none,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedDate = DateTime.now();
                                dateController.text = DateFormat(
                                  'dd/MM/yyyy',
                                ).format(selectedDate);
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
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

                      TextField(
                        controller: noteController,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
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

                      Container(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // IMAGE QUALITY SLIDER
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Image quality',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text('Quality'),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Slider(
                                          activeColor: selectedCat?['color'],
                                          min: 10,
                                          max: 100,
                                          divisions: 9,
                                          label: '$_selectedImageQuality',
                                          value: _selectedImageQuality
                                              .toDouble(),
                                          onChanged: (v) => setState(
                                            () => _selectedImageQuality = v
                                                .round(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('$_selectedImageQuality'),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Add images",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_pickedImages.isNotEmpty)
                                  Text(
                                    "${_pickedImages.length} attached",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            if (_pickedImages.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 92,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _pickedImages.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, index) {
                                    final bytes = _pickedImages[index];
                                    return Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _viewImageFullScreen(bytes),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.memory(
                                              bytes,
                                              width: 92,
                                              height: 92,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () =>
                                                _removePickedImageAt(index),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Add another expense after saving",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            CupertinoSwitch(
                              activeTrackColor: Colors.deepPurple,
                              value: addAnotherAfterSave,
                              onChanged: (v) =>
                                  setState(() => addAnotherAfterSave = v),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _onSavePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CupertinoActivityIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save Expense",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
