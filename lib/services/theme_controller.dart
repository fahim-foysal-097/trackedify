import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackedify/data/theme_schemes.dart';

/// A ThemeOption: can be a FlexScheme or a custom ColorScheme.
class ThemeOption {
  final String
  id; // unique id to persist, e.g., 'flex:mandyRed' or 'custom:my-default-light'
  final String name;
  final FlexScheme? flexScheme;
  final ColorScheme? colorScheme;

  const ThemeOption._({
    required this.id,
    required this.name,
    this.flexScheme,
    this.colorScheme,
  });

  bool get isFlex => flexScheme != null;
  bool get isCustom => colorScheme != null;

  factory ThemeOption.flex(FlexScheme scheme) {
    return ThemeOption._(
      id: 'flex:${scheme.name}',
      name: scheme.name,
      flexScheme: scheme,
    );
  }

  factory ThemeOption.custom(String id, String name, ColorScheme cs) {
    return ThemeOption._(id: 'custom:$id', name: name, colorScheme: cs);
  }
}

class ThemeController extends ChangeNotifier {
  ThemeController._private();
  static final ThemeController instance = ThemeController._private();

  // Pref keys
  static const _kThemeMode = 'themeMode';
  static const _kLightOptionId = 'lightOptionId';
  static const _kDarkOptionId = 'darkOptionId';

  SharedPreferences? _prefs;

  // AVAILABLE options (curated built-ins + custom)
  late final List<ThemeOption> availableLightOptions;
  late final List<ThemeOption> availableDarkOptions;

  // Current selections (persisted ids)
  ThemeOption? _selectedLightOption;
  ThemeOption? _selectedDarkOption;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeOption get selectedLightOption => _selectedLightOption!;
  ThemeOption get selectedDarkOption => _selectedDarkOption!;
  ThemeMode get themeMode => _themeMode;

  /// "default" ids
  static const Set<String> _defaultOptionIds = {
    'custom:default-light', // default light id
    'custom:default-dark', // default dark id
  };

  /// Initialize registry and load saved values
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    // Build curated list from built-in schemes and custom ones
    final builtIns = curatedBuiltInSchemes
        .map((s) => ThemeOption.flex(s))
        .toList();

    // custom options
    final customLight = ThemeOption.custom(
      'default-light',
      'Default',
      defaultLight,
    );
    final customDark = ThemeOption.custom(
      'default-dark',
      'Default',
      defaultDark,
    );

    // For light options
    availableLightOptions = [customLight, ...builtIns];

    // For dark options
    availableDarkOptions = [customDark, ...builtIns];

    // Load persisted ids (or choose defaults)
    final tmIndex = _prefs!.getInt(_kThemeMode) ?? ThemeMode.system.index;
    final lightId =
        _prefs!.getString(_kLightOptionId) ?? availableLightOptions.first.id;
    final darkId =
        _prefs!.getString(_kDarkOptionId) ?? availableDarkOptions.first.id;

    _themeMode =
        ThemeMode.values[tmIndex.clamp(0, ThemeMode.values.length - 1)];
    _selectedLightOption =
        _findById(availableLightOptions, lightId) ??
        availableLightOptions.first;
    _selectedDarkOption =
        _findById(availableDarkOptions, darkId) ?? availableDarkOptions.first;

    notifyListeners();
  }

  ThemeOption? _findById(List<ThemeOption> list, String id) {
    try {
      return list.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setLightOption(ThemeOption opt) async {
    _selectedLightOption = opt;
    await _prefs?.setString(_kLightOptionId, opt.id);
    notifyListeners();
  }

  Future<void> setDarkOption(ThemeOption opt) async {
    _selectedDarkOption = opt;
    await _prefs?.setString(_kDarkOptionId, opt.id);
    notifyListeners();
  }

  /// Create ThemeData for light based on current selection.
  ThemeData getLightThemeData() {
    final opt = selectedLightOption;
    if (opt.isFlex) {
      // use FlexThemeData for built-in FlexScheme
      return FlexThemeData.light(
        scheme: opt.flexScheme!,
        useMaterial3: true,
      ).copyWith(
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      );
    } else {
      // custom ColorScheme -> build ThemeData from it
      return ThemeData.from(
        colorScheme: opt.colorScheme!,
        useMaterial3: true,
      ).copyWith(
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      );
    }
  }

  /// Create ThemeData for dark based on current selection.
  ThemeData getDarkThemeData() {
    final opt = selectedDarkOption;
    if (opt.isFlex) {
      return FlexThemeData.dark(
        scheme: opt.flexScheme!,
        useMaterial3: true,
      ).copyWith(
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      );
    } else {
      return ThemeData.from(
        colorScheme: opt.colorScheme!,
        useMaterial3: true,
      ).copyWith(
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
      );
    }
  }

  // -------------------------
  // Helper methods for overrides
  // -------------------------

  /// Returns whether the currently applied option for the running brightness
  /// is considered the "default" option.
  bool isDefaultSelected({required bool isDark}) {
    final ThemeOption selected = isDark
        ? selectedDarkOption
        : selectedLightOption;
    return _defaultOptionIds.contains(selected.id);
  }

  /// Generic helper to return an "effective" color for roles.
  /// role: 'primary' | 'background' | 'surface' etc.
  Color effectiveColorForRole(
    BuildContext context,
    String role, {
    bool? isDark,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bool dark =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);

    final bool isDefault = isDefaultSelected(isDark: dark);

    switch (role) {
      case 'fab-bg':
        if (isDefault) return Colors.white;
        return cs.onPrimary;
      case 'nav':
        if (isDefault) return Colors.blueAccent;
        return cs.primary;
      case 'overview-1':
        if (isDefault) return const Color.fromARGB(255, 74, 150, 240);
        return cs.primary;
      case 'overview-2':
        if (isDefault) return const Color.fromARGB(255, 74, 130, 240);
        return cs.primary;
      case 'overview-3':
        if (isDefault) return const Color.fromARGB(255, 43, 90, 219);
        return cs.primaryContainer;
      case 'curvedbox-1':
        if (isDefault) return const Color.fromARGB(255, 37, 140, 214);
        return cs.primary;
      case 'curvedbox-2':
        if (isDefault) return const Color.fromARGB(255, 37, 120, 214);
        return cs.primary;
      case 'curvedbox-3':
        if (isDefault) return const Color.fromARGB(255, 35, 90, 209);
        return cs.primaryContainer;
      case 'user-container-1':
        if (isDefault) return const Color(0xFF6C5CE7);
        return cs.primary;
      case 'user-container-2':
        if (isDefault) return const Color(0xFF00B4D8);
        return cs.primaryContainer;
      case 'primary':
        if (isDefault) return Colors.blue;
        return cs.primary;
      case 'lock-bg':
        if (isDefault) return const Color.fromARGB(255, 49, 96, 199);
        return cs.primaryContainer;
      default:
        // fallback to primary if unknown role
        return isDefault ? Colors.blueAccent : cs.primary;
    }
  }
}
