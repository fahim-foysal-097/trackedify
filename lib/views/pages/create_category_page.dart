import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:trackedify/data/category_suggestion_data.dart';
import 'package:trackedify/data/icon_and_color_data.dart';
import 'package:trackedify/database/database_helper.dart';

/// Local suggestion helper (simple on-device "AI" (not really, just rules) using Levenshtein).

class CategorySuggestionHelper {
  final Map<String, CategoryData> dataset;
  CategorySuggestionHelper({required this.dataset});

  // Levenshtein distance (iterative DP)
  int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;
    if (m == 0) return n;
    if (n == 0) return m;

    List<int> prev = List<int>.generate(n + 1, (i) => i);
    List<int> curr = List<int>.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        int cost = s[i - 1] == t[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1, // insertion
          prev[j] + 1, // deletion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      // swap
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    return prev[n];
  }

  /// Suggest a CategoryData for the [input].
  ///
  /// Respects user's explicit choices (if [userPickedIcon] / [userPickedColor] are true
  /// then those fields are not overridden).
  ///
  /// If no close match is found, returns null.
  CategoryData? suggest(
    String input, {
    bool userPickedIcon = false,
    bool userPickedColor = false,
  }) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    if (dataset.isEmpty) return null;

    String? bestKey;
    CategoryData? bestData;
    int? bestDist;

    dataset.forEach((key, data) {
      final k = key.toLowerCase().trim();
      if (k.isEmpty) return;
      final dist = _levenshtein(trimmed, k);
      if (bestDist == null || dist < bestDist!) {
        bestDist = dist;
        bestKey = k;
        bestData = data;
      }
    });

    if (bestDist == null || bestData == null || bestKey == null) return null;

    // normalized distance (0.0..1.0)
    final norm =
        bestDist! /
        (trimmed.length > bestKey!.length ? trimmed.length : bestKey!.length);

    // Only accept suggestions that are reasonably similar.
    // tweak this threshold to be more/less aggressive.
    if (norm > 0.45) return null;

    // return a copy (icon & color present)
    return CategoryData(bestData!.icon, bestData!.color);
  }
}

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({super.key});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

class _CreateCategoryPageState extends State<CreateCategoryPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();

  // Persistent selections
  Color selectedColor = Colors.blue; // initial color (user may change)
  IconData? selectedIcon;

  // Flags to know if user explicitly picked things (so AI never overwrites)
  bool userPickedColor = false;
  bool userPickedIcon = false;

  // AI suggestions (nullable)
  IconData? aiSuggestedIcon;
  Color? aiSuggestedColor;

  // suggestion helper that reads dataset from separate file
  late final CategorySuggestionHelper _suggestionHelper;

  late final Map<String, bool> _expandedCategories;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;
  late final ScrollController _scrollController;
  late final Object _scrollFabHeroTag;
  late final Object _saveFabHeroTag;

  @override
  void initState() {
    super.initState();

    // pass the external dataset into the helper so dataset can be edited independently
    _suggestionHelper = CategorySuggestionHelper(dataset: categoryDataset);

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

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // When user types, compute suggestion immediately.
  void _onNameChanged() {
    final input = _nameController.text;
    final suggestion = _suggestionHelper.suggest(
      input,
      userPickedIcon: userPickedIcon,
      userPickedColor: userPickedColor,
    );

    setState(() {
      // Update AI suggestions but respect user picks
      aiSuggestedIcon = (userPickedIcon) ? null : suggestion?.icon;
      aiSuggestedColor = (userPickedColor) ? null : suggestion?.color;

      // If user hasn't picked a color, auto-apply the suggested color to selectedColor.
      if (!userPickedColor && aiSuggestedColor != null) {
        selectedColor = aiSuggestedColor!;
      }
    });
  }

  void showTipsDialog() {
    const tips =
        'You can add custom categories from here. You can also edit categories from settings page. Also there is smart suggestions for icons and colors.';
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Custom Color', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
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
                selectedColor = picked;
                userPickedColor = true; // user explicitly picked a color
                aiSuggestedColor = null; // clear AI suggestion once user picks
              });
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    // allow saving if either user selected icon or AI suggested one exists
    final iconToSave = selectedIcon ?? aiSuggestedIcon;
    final colorToSave = selectedColor;

    if (name.isEmpty || iconToSave == null) return;

    await DatabaseHelper().addCategory(
      name,
      colorToSave.toARGB32(),
      iconToSave.codePoint,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.deepPurple,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Category "$name" added!')),
          ],
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Helper to pick color from chips
  void _onPickColor(Color color) {
    setState(() {
      selectedColor = color;
      userPickedColor = true;
      aiSuggestedColor = null;
    });
  }

  // Effective color to display: if user hasn't picked but AI suggested exists, prefer AI suggestion
  Color get _effectiveColor {
    if (userPickedColor) return selectedColor;
    return aiSuggestedColor ?? selectedColor;
  }

  // whether there's a valid icon available (user-picked or AI suggestion)
  bool get _hasIconForSave => selectedIcon != null || aiSuggestedIcon != null;

  Widget _buildPreviewCard() {
    final displayIcon =
        selectedIcon ?? aiSuggestedIcon ?? FontAwesomeIcons.tags;
    final showStar = selectedIcon == null && aiSuggestedIcon != null;

    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _effectiveColor,
                  child: Icon(displayIcon, color: Colors.white, size: 28),
                ),
                if (showStar)
                  const Positioned(
                    right: -3,
                    top: -3,
                    child: Icon(Icons.star, size: 16, color: Colors.amber),
                  ),
              ],
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
          for (final color in predefinedColors)
            GestureDetector(
              onTap: () => _onPickColor(color),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _effectiveColor == color
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
                    child: _effectiveColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: _openColorPicker,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _effectiveColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: _effectiveColor.withValues(alpha: 0.18),
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
    final isSuggested =
        (aiSuggestedIcon != null && icon == aiSuggestedIcon && !isSelected);

    return GestureDetector(
      onTap: () => setState(() {
        selectedIcon = icon;
        userPickedIcon = true;
        aiSuggestedIcon = null; // user override
      }),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
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
                color: isSelected ? _effectiveColor : Colors.transparent,
                width: borderWidth,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _effectiveColor.withValues(alpha: 0.36),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: isSelected ? _effectiveColor : Colors.white,
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                if (isSuggested)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber.shade600,
                    ),
                  ),
              ],
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
    final bool canSave =
        _nameController.text.trim().isNotEmpty && _hasIconForSave;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          forceMaterialTransparency: true,
          toolbarHeight: 70,
          elevation: 0,
          title: const Text('Create New Category'),
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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: _scrollFabHeroTag,
                onPressed: _scrollToTop,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Top'),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              const SizedBox(width: 12),
              FloatingActionButton.extended(
                heroTag: _saveFabHeroTag,
                onPressed: canSave ? _saveCategory : null,
                icon: const Icon(Icons.check),
                label: Text(canSave ? 'Save' : 'Enter name & icon'),
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
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
                    hintText: 'Category name',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: _effectiveColor,
                        child: const Icon(
                          FontAwesomeIcons.tags,
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
                            onPressed: () => setState(() {
                              _nameController.clear();
                              aiSuggestedIcon = null;
                              aiSuggestedColor = null;
                              // Keep user picks intact; clearing name doesn't undo explicit picks.
                            }),
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Pick Color',
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
                    'Pick Icon',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
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
