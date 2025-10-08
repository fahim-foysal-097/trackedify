import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/views/widget_tree.dart';
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

  bool isLoading = true;

  // Multi-select state
  bool selectionMode = false;
  Set<int> selectedExpenses = {};

  // Map expenseId -> image count
  Map<int, int> _imageCountMap = {};

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadExpenses();
  }

  Future<void> loadCategories() async {
    setState(() {
      isLoading = true;
    });

    final dbCategories = await DatabaseHelper().getCategories();
    setState(() {
      categoryMap = {
        for (var cat in dbCategories)
          cat['name']: {
            'color': Color(cat['color']),
            'icon': IconData(cat['icon_code'], fontFamily: 'MaterialIcons'),
          },
      };
      isLoading = false;
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

  /// Load expenses and prefetch image counts for visible items.
  Future<void> loadExpenses() async {
    setState(() {
      isLoading = true;
    });

    final db = await DatabaseHelper().database;
    final data = await db.query('expenses', orderBy: 'date DESC, id DESC');

    setState(() {
      expenses = data;
      filteredExpenses = data;
    });

    await _loadImageCountsForExpenses(data);
    await checkTips();

    setState(() {
      isLoading = false;
    });
  }

  /// Efficiently load counts from img_notes for all supplied expenses.
  Future<void> _loadImageCountsForExpenses(
    List<Map<String, dynamic>> data,
  ) async {
    final db = await DatabaseHelper().database;
    if (data.isEmpty) {
      setState(() => _imageCountMap = {});
      return;
    }

    final ids = data.map((e) => e['id'] as int).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT expense_id, COUNT(*) as cnt FROM img_notes WHERE expense_id IN ($placeholders) GROUP BY expense_id',
      ids,
    );
    final Map<int, int> counts = {};
    for (var r in rows) {
      final eid = r['expense_id'] as int;
      final cnt = (r['cnt'] is int)
          ? r['cnt'] as int
          : int.parse(r['cnt'].toString());
      counts[eid] = cnt;
    }

    for (final id in ids) {
      counts[id] = counts[id] ?? 0;
    }

    setState(() {
      _imageCountMap = counts;
    });
  }

  Map<String, dynamic> getCategory(String name) {
    return categoryMap[name] ?? {'color': Colors.grey, 'icon': Icons.category};
  }

  Future<void> deleteExpense(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    // also delete associated img_notes
    try {
      await db.delete('img_notes', where: 'expense_id = ?', whereArgs: [id]);
    } catch (_) {}
    await loadExpenses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Expense deleted')),
            ],
          ),
        ),
      );
    }
  }

  Future<void> deleteMultipleExpenses(Set<int> ids) async {
    final db = await DatabaseHelper().database;
    final int deletedCount = ids.length;
    for (var id in ids) {
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
      try {
        await db.delete('img_notes', where: 'expense_id = ?', whereArgs: [id]);
      } catch (_) {}
    }

    setState(() {
      selectionMode = false;
      selectedExpenses.clear();
    });

    await loadExpenses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('$deletedCount expense(s) deleted')),
            ],
          ),
        ),
      );
    }
  }

  void confirmDelete(Map<String, dynamic> expense) {
    if (showTip) setState(() => showTip = false);

    PanaraConfirmDialog.show(
      context,
      title: 'Delete Expense?',
      message: 'Are you sure you want to delete this expense?',
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () {
        Navigator.pop(context);
      },
      onTapConfirm: () {
        deleteExpense(expense['id']);
        Navigator.pop(context);
      },
      textColor: Colors.grey.shade700,
      panaraDialogType: PanaraDialogType.error,
    );
  }

  void confirmDeleteMultiple(Set<int> ids) {
    final idsCopy = Set<int>.from(ids);

    PanaraConfirmDialog.show(
      context,
      title: 'Delete Selected Expenses?',
      message:
          'Are you sure you want to delete ${idsCopy.length} selected expenses?',
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () => Navigator.pop(context),
      onTapConfirm: () {
        deleteMultipleExpenses(idsCopy);
        Navigator.pop(context);
      },
      textColor: Colors.grey.shade700,
      panaraDialogType: PanaraDialogType.error,
    );
  }

  void openEdit(Map<String, dynamic> expense) {
    if (showTip) setState(() => showTip = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditExpensePage(expense: expense)),
    ).then((_) {
      loadCategories();
      loadExpenses();
    });
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

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return amount.toDouble().toStringAsFixed(2);
    }
    final parsed = double.tryParse(amount?.toString() ?? '');
    if (parsed != null) return parsed.toStringAsFixed(2);
    return amount?.toString() ?? '0.00';
  }

  /// Fetch image blobs for an expense id from img_notes.
  Future<List<Uint8List>> _fetchImagesForExpense(int expenseId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      'img_notes',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    final List<Uint8List> images = [];
    for (final r in rows) {
      final img = r['image'];
      if (img is Uint8List) {
        images.add(img);
      } else if (img is List<int>) {
        images.add(Uint8List.fromList(img));
      } else if (img != null) {
        try {
          images.add(Uint8List.fromList(List<int>.from(img as Iterable<int>)));
        } catch (_) {}
      }
    }
    return images;
  }

  /// Request minimal permissions needed for saving. Returns true if we can proceed.
  Future<bool> _ensureSavePermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else if (Platform.isAndroid) {
        final storage = await Permission.storage.request();
        if (storage.isGranted) return true;
        final photos = await Permission.photos.request();
        return photos.isGranted;
      }
    } catch (_) {}
    return false;
  }

  /// Save bytes to gallery using saver_gallery
  Future<void> _saveBytesToGallery(Uint8List bytes) async {
    final ok = await _ensureSavePermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Cannot save image.')),
      );
      return;
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final name = 'trackedify_$ts.jpg';
    try {
      await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName: name,
        skipIfExists: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Saved to gallery')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
    }
  }

  /// Show image viewer with Save option
  void _showImageViewer(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) {
        if (bytes.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        } else {
          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Flexible(
                  fit: FlexFit.tight,
                  child: InteractiveViewer(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.save_alt,
                            color: Colors.deepPurple,
                          ),
                          label: const Text('Save to gallery'),
                          onPressed: () {
                            Navigator.pop(context); // close viewer
                            _saveBytesToGallery(bytes);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Colors.deepPurple),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _showExpenseDrawer(Map<String, dynamic> expense) async {
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
            child: StatefulBuilder(
              builder: (ctx, modalSetState) {
                return Padding(
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
                                  getCategory(
                                    expense['category'] ?? '',
                                  )['icon'],
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
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(height: 18),
                      // images area
                      FutureBuilder<List<Uint8List>>(
                        future: _fetchImagesForExpense(expense['id'] as int),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Column(
                              children: [
                                SizedBox(
                                  height: 20,
                                  child: Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                                SizedBox(height: 24),
                              ],
                            );
                          }
                          final imgs = snap.data!;
                          if (imgs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Images',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 96,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: imgs.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    final b = imgs[i];
                                    return GestureDetector(
                                      onTap: () => _showImageViewer(b),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          b,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          cacheWidth: 192,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                          );
                        },
                      ),
                      // actions
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 45,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.blue,
                                      ),
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
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 45,
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                confirmDelete(expense);
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      NavBarController.apply();
    });
  }

  void toggleSelection(int id) {
    setState(() {
      if (selectedExpenses.contains(id)) {
        selectedExpenses.remove(id);
      } else {
        selectedExpenses.add(id);
      }
      if (selectedExpenses.isEmpty) selectionMode = false;
    });
  }

  /// Return the IDs of currently visible expenses (filtered view).
  Set<int> _visibleExpenseIds() {
    return filteredExpenses.map<int>((e) => (e['id'] as int)).toSet();
  }

  /// Toggles select all for currently visible (filtered) items.
  void toggleSelectAll() {
    final visible = _visibleExpenseIds();
    setState(() {
      if (visible.isEmpty) return;
      final allSelected = visible.difference(selectedExpenses).isEmpty;
      if (allSelected) {
        selectedExpenses.removeAll(visible);
        if (selectedExpenses.isEmpty) selectionMode = false;
      } else {
        selectedExpenses.addAll(visible);
        selectionMode = true;
      }
    });
  }

  void showTipsDialog() {
    const tips =
        '''Long-press an item to enter multi-select. Use the Select All (top-right) to select visible items. Swipe right to edit, swipe left to delete. Tap an item to view details and you can also save image notes.''';

    PanaraInfoDialog.show(
      context,
      title: 'Hints & Tips',
      message: tips,
      buttonText: 'Got it',
      onTapDismiss: () => Navigator.pop(context),
      textColor: Colors.black54,
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope<Object?>(
        canPop: !selectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (selectionMode) {
            setState(() {
              selectionMode = false;
              selectedExpenses.clear();
            });
            return;
          }
          if (!didPop) Navigator.of(context).maybePop();
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            elevation: selectionMode ? 2 : 4,
            backgroundColor: selectionMode
                ? Colors.blue.shade700
                : Colors.white,
            foregroundColor: selectionMode ? Colors.white : Colors.black87,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) {
                return FadeTransition(opacity: anim, child: child);
              },
              child: selectionMode
                  ? Text(
                      '${selectedExpenses.length} selected',
                      key: const ValueKey('selected-title'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  : const Text(
                      "Expense History",
                      key: ValueKey('normal-title'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            centerTitle: false,
            leading: IconButton(
              tooltip: "Back",
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
              onPressed: () => Navigator.pop(context),
            ),
            actionsPadding: const EdgeInsets.only(right: 6),
            actions: selectionMode
                ? [
                    IconButton(
                      tooltip: 'Select all visible',
                      icon: const Icon(Icons.select_all),
                      onPressed: toggleSelectAll,
                      color: Colors.white,
                    ),
                    IconButton(
                      tooltip: 'Clear selection',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          selectionMode = false;
                          selectedExpenses.clear();
                        });
                      },
                      color: Colors.white,
                    ),
                  ]
                : [
                    IconButton(
                      tooltip: 'Tips',
                      icon: const Icon(Icons.lightbulb_outline),
                      onPressed: showTipsDialog,
                    ),
                  ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: filterExpenses,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: "Search expenses",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: filteredExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No expenses to show',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: filteredExpenses.length + (showTip ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (showTip && index == 1) {
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
                    final isSelected = selectedExpenses.contains(expense['id']);
                    final imageCount = _imageCountMap[expense['id']] ?? 0;

                    // subtitle content with image indicator first
                    final subtitleWidgets = <Widget>[];
                    subtitleWidgets.add(
                      Text(
                        expense['date'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                    if (imageCount > 0 || noteText.isNotEmpty) {
                      subtitleWidgets.add(const SizedBox(height: 6));
                      subtitleWidgets.add(
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (imageCount > 0) ...[
                              GestureDetector(
                                onTap: () {
                                  _showExpenseDrawer(expense);
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.solidImage,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$imageCount',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (noteText.isNotEmpty) ...[
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showExpenseDrawer(expense),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.solidNoteSticky,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
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
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    final subtitle = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subtitleWidgets,
                    );

                    final itemChild = Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (selectionMode) {
                              toggleSelection(expense['id']);
                            } else {
                              _showExpenseDrawer(expense);
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              selectionMode = true;
                              toggleSelection(expense['id']);
                            });
                          },
                          leading: selectionMode
                              ? Checkbox(
                                  activeColor: Colors.blue,
                                  focusColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  value: isSelected,
                                  onChanged: (_) =>
                                      toggleSelection(expense['id']),
                                )
                              : CircleAvatar(
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
                          subtitle: subtitle,
                          trailing: Text(
                            "-\$${_formatAmount(expense['amount'])}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );

                    if (selectionMode) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: itemChild,
                      );
                    }

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
                              Text(
                                "Edit",
                                style: TextStyle(color: Colors.white),
                              ),
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
                        child: itemChild,
                      ),
                    );
                  },
                ),
          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectionMode
                ? FloatingActionButton.extended(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    key: const ValueKey('delete-fab'),
                    onPressed: selectedExpenses.isEmpty
                        ? null
                        : () => confirmDeleteMultiple(
                            Set<int>.from(selectedExpenses),
                          ),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: Text(
                      'Delete (${selectedExpenses.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: selectedExpenses.isEmpty
                        ? Colors.grey
                        : Colors.red,
                  )
                : const SizedBox.shrink(),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }
}
