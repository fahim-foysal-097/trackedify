import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/constants/icon_data.dart';

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({super.key});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  Color selectedColor = Colors.blue;
  IconData? selectedIcon;

  bool get _iconPicked => selectedIcon != null;

  late final Map<String, bool> _expandedCategories;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final ScrollController _scrollController;

  // unique hero tags for FABs (stable for this page instance)
  late final Object _scrollFabHeroTag;
  late final Object _saveFabHeroTag;

  @override
  void initState() {
    super.initState();

    // Expand all categories by default
    _expandedCategories = {
      for (final entry in iconCategories.entries) entry.key: true,
    };

    _nameController.addListener(_onNameChanged);

    // pulsing animation for selected icon border
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _scrollController = ScrollController();

    // unique hero tags
    _scrollFabHeroTag = UniqueKey();
    _saveFabHeroTag = UniqueKey();
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void showTipsDialog() {
    const tips =
        '''You can add custom categories from here. You can also edit categories from settings page.''';

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

  Future<void> _openColorPicker() async {
    Color picked = selectedColor;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Select Custom Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) => picked = color,
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => selectedColor = picked);
              Navigator.pop(context);
            },
            child: const Text("Select"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || !_iconPicked) return;

    await DatabaseHelper().addCategory(
      name,
      selectedColor.toARGB32(),
      selectedIcon!.codePoint,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Category "$name" added!')));
    Navigator.pop(context, true);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      // A smooth animated scroll with decelerating curve.
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildPreviewCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: selectedColor,
              child: Icon(
                selectedIcon ?? FontAwesomeIcons.tag,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.trim().isEmpty
                        ? 'Category preview'
                        : _nameController.text.trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Icon & color preview',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Pick color',
              onPressed: _openColorPicker,
              icon: const Icon(Icons.color_lens_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChips() {
    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          // predefined colors
          for (final color in predefinedColors)
            GestureDetector(
              onTap: () => setState(() => selectedColor = color),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: selectedColor == color
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 8.0,
                              spreadRadius: 1.5,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4.0,
                              spreadRadius: 0.2,
                            ),
                          ],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: color,
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),

          // custom color pick button
          GestureDetector(
            onTap: _openColorPicker,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.18),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.palette, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconTile(IconData icon) {
    final isSelected = icon == selectedIcon;

    return GestureDetector(
      onTap: () => setState(() => selectedIcon = icon),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          // animated border width and blur (double values)
          final double borderWidth = isSelected
              ? (2.0 + _pulseAnim.value * 4.0)
              : 0.0;
          final double blur = isSelected ? (4.0 + _pulseAnim.value * 6.0) : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            transform: isSelected
                ? (Matrix4.identity()..scaleByDouble(1.08, 1.08, 1.08, 1.08))
                : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? selectedColor : Colors.transparent,
                width: borderWidth,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.36),
                        blurRadius: blur,
                        spreadRadius: 1.0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        spreadRadius: 0.2,
                      ),
                    ],
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: isSelected ? selectedColor : Colors.white,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconCategory(String title, List<IconData> icons, bool expanded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // category header - NO background, transparent look
        InkWell(
          onTap: () => setState(
            () => _expandedCategories[title] =
                !(_expandedCategories[title] ?? true),
          ),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: icons.length,
            padding: const EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width >= 720 ? 12 : 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, idx) => _buildIconTile(icons[idx]),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = _nameController.text.trim().isNotEmpty && _iconPicked;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          forceMaterialTransparency: true,
          toolbarHeight: 70,
          elevation: 0,
          title: const Text("Create New Category"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actionsPadding: const EdgeInsets.only(right: 12),
          actions: [
            IconButton(
              tooltip: 'Tips',
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: showTipsDialog,
            ),
          ],
        ),
        // two FABs as same-height extended buttons with unique hero tags and solid colors (no alpha)
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left FAB: scroll to top (extended to match save)
              FloatingActionButton.extended(
                heroTag: _scrollFabHeroTag,
                onPressed: _scrollToTop,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Top'),
                // solid modern color, no alpha
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              const SizedBox(width: 12),
              // Right FAB: Save
              FloatingActionButton.extended(
                heroTag: _saveFabHeroTag,
                onPressed: canSave ? _saveCategory : null,
                icon: const Icon(Icons.check),
                label: Text(canSave ? 'Save' : 'Enter name & icon'),
                // solid modern teal color, no alpha
                backgroundColor: canSave
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade300,
                foregroundColor: canSave ? Colors.white : Colors.grey.shade700,
                elevation: 4,
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: ListView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 8),
              _buildPreviewCard(),
              const SizedBox(height: 18),

              // modern reimagined name field inside a subtle card container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      spreadRadius: 0.6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Category name",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: selectedColor,
                        child: const Icon(
                          FontAwesomeIcons.tag,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    suffixIcon: _nameController.text.trim().isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _nameController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Centered "Pick Color"
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Pick Color",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              _buildColorChips(),
              const SizedBox(height: 20),

              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Pick Icon",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),

              // icon categories list
              for (final entry in iconCategories.entries)
                _buildIconCategory(
                  entry.key,
                  entry.value,
                  _expandedCategories[entry.key] ?? true,
                ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
