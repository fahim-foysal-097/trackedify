import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:spendle/services/notification_service.dart';
import 'package:spendle/shared/constants/constants.dart';
import 'package:spendle/views/widget_tree.dart';
import 'package:spendle/views/pages/set_pin_page.dart';
import 'package:spendle/services/auth_gate.dart';
import 'package:spendle/database/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
          title: 'Spendle Reminder',
          body: 'Don\'t forget to add your expenses today.',
          hour: 16,
          minute: 30,
        );
      } else {
        // user denied OS-level permission; do not schedule
      }
    } else {
      // cancel previously scheduled reminders if any
      await notifUtil.cancelAllSchedules();
    }
  } catch (e) {
    // If DB or notifications fail, continue to run app but log if needed.
    // print('Notification init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spendle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          primary: const Color(0xFF00b4d8),
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
