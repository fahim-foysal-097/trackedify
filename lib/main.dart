import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';
import 'package:trackedify/services/notification_service.dart';
import 'package:trackedify/shared/constants/constants.dart';
import 'package:trackedify/views/widget_tree.dart';
import 'package:trackedify/views/pages/set_pin_page.dart';
import 'package:trackedify/services/auth_gate.dart';
import 'package:trackedify/database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Awesome Notifications and schedule if DB enables it.
  final notifUtil = NotificationUtil(
    awesomeNotifications: AwesomeNotifications(),
  );
  await notifUtil.init();

  // Read DB preference and schedule/cancel before runApp
  try {
    final db = DatabaseHelper();
    final enabled = await db.isNotificationEnabled();

    if (enabled) {
      // Request permission
      final granted = await notifUtil.requestPermission();

      if (!granted) {
        // Redirect to exact alarm permission page (Android 12+)
        await AwesomeNotifications().showAlarmPage();
      }

      if (granted) {
        // Scheduled Notification
        await notifUtil.scheduleDailyAt(
          id: AppConstants.dailyReminderId,
          channelKey: AppStrings.scheduledChannelKey,
          title: 'Trackedify Reminder',
          body: 'Don\'t forget to add your expenses today.',
          hour: 20,
          minute: 00,
        );
      } else {
        // user denied OS-level permission; do not schedule
      }
    } else {
      // cancel previously scheduled reminders if any
      await notifUtil.cancelAllSchedules();
    }
  } catch (e) {
    // DB or notifications failed
    // print('Notification init failed: $e');
  }

  NavBarController.apply;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Assigning the global key
      title: 'Trackedify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          primary: Colors.deepPurple,
          secondary: const Color(0xFF56CCF2),
          tertiary: const Color(0xFF2F80ED),
          brightness: Brightness.light,
          surface: Colors.grey.shade100,
        ),
      ),
      routes: {'/set-pin': (context) => const SetPinPage()},
      home: const AuthGate(child: WidgetTree()),
    );
  }
}
