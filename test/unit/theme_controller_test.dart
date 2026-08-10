import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackedify/services/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController & ThemeOption', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemeController.instance.load();
    });

    test('ThemeOption.flex sets correct properties', () {
      final option = ThemeOption.flex(FlexScheme.mandyRed);

      expect(option.id, equals('flex:mandyRed'));
      expect(option.name, equals('mandyRed'));
      expect(option.isFlex, isTrue);
      expect(option.isCustom, isFalse);
    });

    test('ThemeOption.custom sets correct properties', () {
      const cs = ColorScheme.light();
      final option = ThemeOption.custom('test-light', 'Test Light', cs);

      expect(option.id, equals('custom:test-light'));
      expect(option.name, equals('Test Light'));
      expect(option.colorScheme, equals(cs));
      expect(option.isCustom, isTrue);
      expect(option.isFlex, isFalse);
    });

    test('ThemeController initializes default theme options', () {
      final controller = ThemeController.instance;

      expect(controller.availableLightOptions.isNotEmpty, isTrue);
      expect(controller.availableDarkOptions.isNotEmpty, isTrue);
      expect(controller.selectedLightOption.id, equals('custom:default-light'));
      expect(controller.selectedDarkOption.id, equals('custom:default-dark'));
      expect(controller.themeMode, equals(ThemeMode.system));
    });

    test('setThemeMode updates themeMode state', () async {
      final controller = ThemeController.instance;

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, equals(ThemeMode.dark));

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, equals(ThemeMode.light));
    });
  });
}
