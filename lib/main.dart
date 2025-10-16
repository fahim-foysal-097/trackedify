import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:trackedify/services/notification_service.dart';
import 'package:trackedify/services/theme_controller.dart';
import 'package:trackedify/shared/constants/constants.dart';
import 'package:trackedify/views/pages/settings/theme_settings.dart';
import 'package:trackedify/views/widget_tree.dart';
import 'package:trackedify/views/pages/set_pin_page.dart';
import 'package:trackedify/services/auth_gate.dart';
import 'package:trackedify/database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Awesome Notifications
  final notifUtil = NotificationUtil(
    awesomeNotifications: AwesomeNotifications(),
  );
  await notifUtil.init();

  // Check DB preference and schedule/cancel before runApp
  try {
    final db = DatabaseHelper();
    final enabled = await db.isNotificationEnabled();

    if (enabled) {
      final granted = await notifUtil.requestPermission();

      if (!granted) {
        // Request OS-level permission page (Android 12+)
        await AwesomeNotifications().showAlarmPage();
      }

      if (!granted) {
        // Persist the user's implicit choice (deny) into DB to avoid repeated prompts.
        await db.setNotificationEnabled(false);
        if (kDebugMode) {
          debugPrint(
            'Notification permission denied -> saved preference to disabled.',
          );
        }
      } else {
        // Permission granted -> schedule the next one-shot reminder.
        final time = await db.getNotificationTime();
        final hour = time['hour'] ?? 20;
        final minute = time['minute'] ?? 0;

        // scheduleDailyAt cancels any existing noti by ID and create next one-shot.
        await notifUtil.scheduleDailyAt(
          id: AppConstants.dailyReminderId,
          channelKey: AppStrings.scheduledChannelKey,
          title: 'Trackedify Reminder',
          body: 'Don\'t forget to add your expenses today.',
          hour: hour,
          minute: minute,
        );
      }
    } else {
      // If disabled in DB, ensure there are no reminders scheduled.
      await notifUtil.cancelById(AppConstants.dailyReminderId);
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Notification init failed: $e');
  }

  // Load theme controller & options
  await ThemeController.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static final navKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController ctrl = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    ctrl.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navKey,
      title: 'Trackedify',
      theme: ctrl.getLightThemeData(),
      darkTheme: ctrl.getDarkThemeData(),
      themeMode: ctrl.themeMode,
      routes: {
        '/set-pin': (ctx) => const SetPinPage(),
        '/theme-settings': (ctx) => const ThemeSettingsPage(),
      },
      home: const AuthGate(child: WidgetTree()),
    );
  }
}
