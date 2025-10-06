import 'package:flutter/foundation.dart';
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

      if (granted) {
        // Get saved time (defaults to 20:00)
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
      // If disabled, cancel any scheduled reminder by ID
      await notifUtil.cancelById(AppConstants.dailyReminderId);
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Notification init failed: $e');
  }

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
