import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:trackedify/database/database_helper.dart';
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
    await checkTips();
    isLoading = false;
  }

  Map<String, dynamic> getCategory(String name) {
    return categoryMap[name] ?? {'color': Colors.grey, 'icon': Icons.category};
  }

  Future<void> deleteExpense(int id) async {
    final db = await DatabaseHelper().database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
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
    // delete each id (simple approach—keep as-is to match your DB helper)
    for (var id in ids) {
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    }

    // clear selection AFTER we've captured the count and finished DB ops
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
        // pass the copied set
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
            ),
          ),
        );
      },
    );
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
      // if everything visible already selected -> clear
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
        '''Long-press an item to enter multi-select. Use the Select All (top-right) to select visible items. Swipe right to edit, swipe left to delete. Tap an item to view details and note.''';

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
          // If selection mode is active and a pop was attempted, clear selection instead of popping.
          if (selectionMode) {
            setState(() {
              selectionMode = false;
              selectedExpenses.clear();
            });
            return;
          }
          // If pop wasn't performed by the system for some reason, try popping manually.
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
                    // Select All / Visible items
                    IconButton(
                      tooltip: 'Select all visible',
                      icon: const Icon(Icons.select_all),
                      onPressed: toggleSelectAll,
                      color: Colors.white,
                    ),
                    // Clear selection (quick)
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
                    // Tips icon in normal mode
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
                      // Tip in "callout" style
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense['date'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (noteText.isNotEmpty) ...[
                                GestureDetector(
                                  onTap: () => _showExpenseDrawer(expense),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        FontAwesomeIcons.solidNoteSticky,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
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
                              ],
                            ],
                          ),
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
          // Floating action delete button when in selection mode (animated)
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
          // move FAB to the bottom-right
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }
}
