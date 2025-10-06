import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/data/icon_and_color_data.dart';
import 'package:trackedify/views/pages/create_category_page.dart';
import 'package:trackedify/views/widget_tree.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class EditCategoriesPage extends StatefulWidget {
  const EditCategoriesPage({super.key});

  @override
  State<EditCategoriesPage> createState() => _EditCategoriesPageState();
}

class _EditCategoriesPageState extends State<EditCategoriesPage> {
  final dbHelper = DatabaseHelper();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';

  // selection state
  final Set<int> _selectedIds = {};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  late final List<IconData> availableIcons;
  late final List<Color> colorOptions;

  // shared gradient for AppBar + header container
  static const LinearGradient _headerGradient = LinearGradient(
    colors: [Color(0xFF5B2AF5), Color(0xFF8A46FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    availableIcons = iconCategories.values.expand((l) => l).toList();
    colorOptions = predefinedColors;
    _reload();
  }

  void _showTips() {
    PanaraInfoDialog.show(
      context,
      title: "Tips",
      message: "You can delete multiple categories at once by long-pressing.",
      buttonText: "Got it",
      textColor: Colors.black54,
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final rows = await dbHelper.getCategories();
    setState(() {
      _categories = rows;
      _applyFilter();
      _loading = false;
      _selectedIds.clear(); // clear selection after reload
    });
  }

  void _applyFilter() {
    if (_search.trim().isEmpty) {
      _filtered = List.from(_categories);
    } else {
      final q = _search.toLowerCase();
      _filtered = _categories.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    }
  }

  // Toggle selection of a single id
  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Select all visible (filtered) or clear selection
  void _toggleSelectAll() {
    setState(() {
      final visibleIds = _filtered.map((r) => r['id'] as int).toSet();
      final allSelected =
          visibleIds.isNotEmpty && visibleIds.difference(_selectedIds).isEmpty;
      if (allSelected) {
        _selectedIds.removeAll(visibleIds);
      } else {
        _selectedIds.addAll(visibleIds);
      }
    });
  }

  Future<void> _confirmAndDeleteSingle(int id, String name) async {
    final confirmed = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete category?",
      message:
          "Delete \"$name\"? Existing expenses that used this category will keep the text value.",
      textColor: Colors.black54,
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () => Navigator.pop(context, false),
      onTapConfirm: () => Navigator.pop(context, true),
      panaraDialogType: PanaraDialogType.error,
    );

    if (confirmed != true) return;

    final db = await dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        content: Row(
          children: [
            Icon(FontAwesomeIcons.trash, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Category deleted')),
          ],
        ),
      ),
    );
    await _reload();
  }

  // Bulk delete selected IDs
  Future<void> _confirmAndDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete selected categories?",
      message:
          "Delete ${_selectedIds.length} selected categories? This action cannot be undone. Existing expenses that used these categories will keep their text value.",
      textColor: Colors.black54,
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () => Navigator.pop(context, false),
      onTapConfirm: () => Navigator.pop(context, true),
      panaraDialogType: PanaraDialogType.error,
    );

    if (confirmed != true) return;

    final ids = _selectedIds.toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final db = await dbHelper.database;
    await db.delete(
      'categories',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        content: Row(
          children: [
            const Icon(FontAwesomeIcons.trash, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Deleted ${ids.length} categories')),
          ],
        ),
      ),
    );

    setState(() {
      _selectedIds.clear();
    });

    await _reload();
  }

  Future<void> _openCreatePage() async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCategoryPage()),
    );
    if (res == true) {
      await _reload();
    }
    // keep existing behavior
    try {
      NavBarController.apply();
    } catch (_) {}
  }

  Future<void> _openEditSheet(Map<String, dynamic> category) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditCategorySheet(
        category: category,
        availableIcons: availableIcons,
        colorOptions: colorOptions,
      ),
    );

    if (result == true) {
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Category saved')),
            ],
          ),
        ),
      );
    }
    try {
      NavBarController.apply();
    } catch (_) {}
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search categories',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          setState(() {
            _search = v;
            _applyFilter();
          });
        },
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Column(
        children: [
          SizedBox(height: 150),
          Center(child: CupertinoActivityIndicator(radius: 11)),
        ],
      );
    }

    if (_filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            const SizedBox(height: 28),
            Icon(FontAwesomeIcons.tags, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 18),
            Text(
              'No categories found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap Add to create your first category.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filtered.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = _filtered[index];
        final id = row['id'] as int;
        final name = row['name']?.toString() ?? '';
        final colorInt = row['color'] as int? ?? Colors.blue.toARGB32();
        final iconCode = row['icon_code'] as int? ?? Icons.label.codePoint;

        final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
        final color = Color(colorInt);

        final selected = _selectedIds.contains(id);

        return Material(
          color: Colors.white,
          elevation: 0,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              if (_selectionMode) {
                _toggleSelection(id);
                return;
              }
              _openEditSheet(row);
            },
            onLongPress: () {
              // enter selection mode / toggle
              _toggleSelection(id);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.deepPurple.withValues(alpha: 0.3)
                      : Colors.grey.shade100,
                  width: selected ? 4 : 3,
                ),
                color: selected
                    ? Colors.deepPurple.withValues(alpha: 0.04)
                    : null,
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      if (selected)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Keep UI same: icons visible. While selecting, tapping them toggles selection
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () {
                      if (_selectionMode) {
                        _toggleSelection(id);
                      } else {
                        _openEditSheet(row);
                      }
                    },
                    icon: const Icon(FontAwesomeIcons.pen, size: 16),
                    splashRadius: 22,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () {
                      if (_selectionMode) {
                        _toggleSelection(id);
                      } else {
                        _confirmAndDeleteSingle(id, name);
                      }
                    },
                    icon: const Icon(FontAwesomeIcons.trash, size: 16),
                    color: Colors.red.shade400,
                    splashRadius: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: const BoxDecoration(
        gradient: _headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _selectionMode
                ? Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const Text(
                    'Categories',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          ElevatedButton.icon(
            onPressed: _openCreatePage,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar uses same gradient via flexibleSpace to visually match the header container
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope<Object?>(
        canPop: !_selectionMode,
        onPopInvokedWithResult: (didPop, result) {
          // If selection mode is active and a pop was attempted, clear selection instead of popping.
          if (_selectionMode) {
            setState(() {
              _selectedIds.clear();
            });
            return;
          }
          // If pop wasn't performed by the system for some reason, try popping manually.
          if (!didPop) Navigator.of(context).maybePop();
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              _selectionMode ? 'Delete Multiple' : 'Edit Categories',
              style: const TextStyle(color: Colors.white),
            ),
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 25,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: _headerGradient),
            ),
            backgroundColor: Colors.transparent,
            actionsPadding: const EdgeInsets.only(right: 2),
            actions: [
              if (!_selectionMode)
                IconButton(
                  tooltip: 'Tips',
                  icon: const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                  ),
                  onPressed: _showTips,
                ),
              if (_selectionMode)
                IconButton(
                  onPressed: _toggleSelectAll,
                  icon: const Icon(Icons.select_all, color: Colors.white),
                  tooltip: 'Select all',
                ),
            ],
          ),
          floatingActionButton: _selectionMode
              ? FloatingActionButton(
                  onPressed: _confirmAndDeleteSelected,
                  backgroundColor: Colors.red.shade600,
                  child: const Icon(
                    FontAwesomeIcons.trash,
                    color: Colors.white,
                    size: 18,
                  ),
                )
              : null,
          body: RefreshIndicator(
            color: Colors.deepPurple,
            onRefresh: _reload,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeaderRow()),
                SliverToBoxAdapter(child: _buildSearch()),
                SliverToBoxAdapter(child: _buildList()),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(height: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared Edit bottom sheet (kept visually identical; internals fixed to use .value and withOpacity)
class EditCategorySheet extends StatefulWidget {
  final Map<String, dynamic>? category;
  final List<IconData> availableIcons;
  final List<Color> colorOptions;

  const EditCategorySheet({
    super.key,
    this.category,
    required this.availableIcons,
    required this.colorOptions,
  });

  @override
  State<EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<EditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _selectedIconCode;
  late Color _selectedColor;
  bool _saving = false;

  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(
      text: cat != null ? (cat['name'] ?? '') : '',
    );
    _selectedIconCode = cat != null
        ? (cat['icon_code'] as int? ?? Icons.label.codePoint)
        : (widget.availableIcons.isNotEmpty
              ? widget.availableIcons.first.codePoint
              : Icons.label.codePoint);
    _selectedColor = cat != null
        ? Color(cat['color'] as int)
        : (widget.colorOptions.isNotEmpty
              ? widget.colorOptions.first
              : Colors.blue);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<bool> _isNameDuplicate(String name, {int? excludeId}) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'categories',
      where: excludeId != null ? 'name = ? AND id != ?' : 'name = ?',
      whereArgs: excludeId != null ? [name, excludeId] : [name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final isDuplicate = await _isNameDuplicate(
      name,
      excludeId: widget.category != null ? widget.category!['id'] as int : null,
    );
    if (isDuplicate) {
      setState(() => _saving = false);
      if (!mounted) return;
      PanaraInfoDialog.show(
        context,
        title: "Name already used",
        message: "A category with that name already exists. Pick another name.",
        buttonText: "OK",
        onTapDismiss: () => Navigator.pop(context),
        textColor: Colors.black54,
        panaraDialogType: PanaraDialogType.normal,
      );
      return;
    }

    final db = await dbHelper.database;
    if (widget.category != null) {
      final id = widget.category!['id'] as int;
      await db.update(
        'categories',
        {
          'name': name,
          'color': _selectedColor.toARGB32(),
          'icon_code': _selectedIconCode,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('categories', {
        'name': name,
        'color': _selectedColor.toARGB32(),
        'icon_code': _selectedIconCode,
      });
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true);
  }

  Future<void> _openColorPicker() async {
    Color picked = _selectedColor;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Custom Color', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => picked = color,
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.7,
            pickerAreaBorderRadius: BorderRadius.circular(10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedColor = picked;
              });
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableIcons.map((ic) {
        final selected = ic.codePoint == _selectedIconCode;
        return Material(
          color: selected
              ? _selectedColor.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () => setState(() => _selectedIconCode = ic.codePoint),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(
                IconData(ic.codePoint, fontFamily: 'MaterialIcons'),
                size: selected ? 28 : 24,
                color: selected ? _selectedColor : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorPalette() {
    final bool isCustom = !widget.colorOptions.any(
      (c) => c.toARGB32() == _selectedColor.toARGB32(),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...widget.colorOptions.map((c) {
          final selected = c.toARGB32() == _selectedColor.toARGB32();
          return GestureDetector(
            onTap: () => setState(() => _selectedColor = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: selected ? 46 : 40,
              width: selected ? 46 : 40,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        }),
        GestureDetector(
          onTap: _openColorPicker,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: isCustom ? 46 : 40,
            width: isCustom ? 46 : 40,
            decoration: BoxDecoration(
              color: isCustom ? _selectedColor : Colors.transparent,
              shape: BoxShape.circle,
              border: isCustom ? null : Border.all(color: Colors.grey.shade300),
              boxShadow: isCustom
                  ? [
                      BoxShadow(
                        color: _selectedColor.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                Icons.color_lens,
                color: isCustom ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 60,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Text(
                  'Edit Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Name, icon and color help categorize expenses.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: _selectedColor.withValues(
                              alpha: 0.12,
                            ),
                            child: Icon(
                              IconData(
                                _selectedIconCode,
                                fontFamily: 'MaterialIcons',
                              ),
                              color: _selectedColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Category Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Name required';
                                }
                                if (v.trim().length < 2) return 'Too short';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade800,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _saving
                                  ? const Center(
                                      child: SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CupertinoActivityIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Save changes',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pick a color',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildColorPalette(),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pick an icon',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildIconGrid(),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
