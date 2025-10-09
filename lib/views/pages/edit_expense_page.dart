import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/views/pages/calculator.dart';
import 'package:trackedify/views/pages/create_category_page.dart';
import 'package:trackedify/views/widget_tree.dart';

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

  // image handling
  final ImagePicker _picker = ImagePicker();

  // existing images loaded from DB (each item: {'id': int, 'bytes': Uint8List})
  final List<Map<String, dynamic>> _existingImages = [];

  // newly picked images (not yet in DB): list of Uint8List
  final List<Uint8List> _newPickedImages = [];

  // UI: image quality (1-100) passed to image_picker; default 38
  int _selectedImageQuality = 40;

  final String tips =
      '''You can edit the amount, date, category and note. Attach images (optional) and choose image quality before picking. Long-press a category to delete it.''';

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
    _loadExistingImages();
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
      // fallback raw query if generic method fails
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
      textColor: Colors.black54,
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.warning,
    );

    if (!mounted) return;
    final really = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete Category?",
      message: 'Are you sure you want to delete "$name"?',
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      textColor: Colors.black54,
      onTapCancel: () => Navigator.pop(context, false),
      onTapConfirm: () => Navigator.pop(context, true),
      panaraDialogType: PanaraDialogType.error,
    );

    if (really == true) {
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
    ).then((_) {
      NavBarController.apply();
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1975),
      lastDate: DateTime(2060),
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
                      if (_existingImages.isNotEmpty ||
                          _newPickedImages.isNotEmpty) ...[
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
                            itemCount:
                                _existingImages.length +
                                _newPickedImages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              if (i < _existingImages.length) {
                                return GestureDetector(
                                  onTap: () => _viewImageFullScreen(
                                    _existingImages[i]['bytes'] as Uint8List,
                                  ),
                                  child: Image.memory(
                                    _existingImages[i]['bytes'] as Uint8List,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              } else {
                                final idx = i - _existingImages.length;
                                return GestureDetector(
                                  onTap: () => _viewImageFullScreen(
                                    _newPickedImages[idx],
                                  ),
                                  child: Image.memory(
                                    _newPickedImages[idx],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                            },
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

  // -------------------------
  // Image helpers
  // -------------------------

  Future<void> _loadExistingImages() async {
    _existingImages.clear();
    final dbHelper = DatabaseHelper();
    final rows = await dbHelper.getImageNotes(
      expenseId: widget.expense['id'] as int,
    );
    for (final r in rows) {
      dynamic imgData = r['image'];
      Uint8List? bytes;
      if (imgData is Uint8List) {
        bytes = imgData;
      } else if (imgData is List<int>) {
        bytes = Uint8List.fromList(imgData);
      } else if (imgData is String) {
        // Unlikely, but handle base64 stored strings
        try {
          bytes = Uint8List.fromList(List<int>.from(imgData.codeUnits));
        } catch (_) {
          bytes = null;
        }
      } else {
        bytes = null;
      }

      if (bytes != null) {
        _existingImages.add({
          'id': r['id'],
          'bytes': bytes,
          'caption': r['caption'],
        });
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickImages() async {
    try {
      // Use user-selected image quality value
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: _selectedImageQuality,
        maxHeight: 1920,
        maxWidth: 1080,
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
          _newPickedImages.add(bytes);
        }
      } finally {
        if (mounted) Navigator.of(context).pop();
      }

      if (mounted) setState(() {});
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Image pick failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick images')));
    }
  }

  Future<void> _deleteExistingImage(int id) async {
    final confirm = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete image?",
      message: "Delete this attached image?",
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () => Navigator.pop(context, false),
      onTapConfirm: () => Navigator.pop(context, true),
      textColor: Colors.black54,
      panaraDialogType: PanaraDialogType.error,
    );

    if (confirm != true) return;

    final dbHelper = DatabaseHelper();
    await dbHelper.deleteImageNote(id);
    _existingImages.removeWhere((e) => e['id'] == id);
    if (mounted) setState(() {});
  }

  void _removeNewPickedImageAt(int index) {
    setState(() {
      _newPickedImages.removeAt(index);
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

  Future<void> _saveNewImagesForExpense(int expenseId) async {
    if (_newPickedImages.isEmpty) return;
    final dbHelper = DatabaseHelper();
    for (final bytes in _newPickedImages) {
      // insertion expects Uint8List
      await dbHelper.insertImageNote(
        expenseId: expenseId,
        image: bytes,
        caption: null,
      );
    }
    _newPickedImages.clear();
  }

  // -------------------------
  // Save flow
  // -------------------------
  Future<void> saveChanges() async {
    FocusScope.of(context).unfocus();

    if (selectedCategoryName == null || selectedCategoryName!.isEmpty) {
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

    final amount = double.tryParse(expenseController.text);
    if (amount == null || amount <= 0) {
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

      // save any new images
      final expenseId = widget.expense['id'] as int;
      await _saveNewImagesForExpense(expenseId);

      await _loadExistingImages();

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

                    // IMAGE QUALITY + ATTACH IMAGES BLOCK
                    Container(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Quality'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Slider(
                                  activeColor: Colors.deepPurple,
                                  min: 10,
                                  max: 100,
                                  divisions: 9,
                                  label: '$_selectedImageQuality',
                                  value: _selectedImageQuality.toDouble(),
                                  onChanged: (v) => setState(
                                    () => _selectedImageQuality = v.round(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$_selectedImageQuality'),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(
                                  Icons.photo_library,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Attach images',
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
                              if (_existingImages.isNotEmpty ||
                                  _newPickedImages.isNotEmpty)
                                Text(
                                  '${_existingImages.length + _newPickedImages.length} attached',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (_existingImages.isNotEmpty) ...[
                            const Text(
                              'Existing images',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _existingImages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, index) {
                                  final item = _existingImages[index];
                                  return Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _viewImageFullScreen(
                                          item['bytes'] as Uint8List,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.memory(
                                            item['bytes'] as Uint8List,
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
                                          onTap: () => _deleteExistingImage(
                                            item['id'] as int,
                                          ),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(
                                                Icons.delete,
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

                          if (_newPickedImages.isNotEmpty) ...[
                            const Text(
                              'New images',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _newPickedImages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, index) {
                                  final bytes = _newPickedImages[index];
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
                                              _removeNewPickedImageAt(index),
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
                            const SizedBox(height: 12),
                          ],
                        ],
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
