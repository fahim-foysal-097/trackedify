import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:trackedify/shared/constants/constants.dart';

class NotificationUtil {
  final AwesomeNotifications awesomeNotifications;

  NotificationUtil({required this.awesomeNotifications});

  Future<void> init() async {
    await awesomeNotifications.initialize(null, [
      NotificationChannel(
        channelKey: AppStrings.basicChannelKey,
        channelName: AppStrings.basicChannelName,
        channelDescription: AppStrings.basicChannelDescription,
        defaultColor: const Color(0xFF6C63FF),
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelKey: AppStrings.scheduledChannelKey,
        channelName: AppStrings.scheduledChannelName,
        channelDescription: AppStrings.scheduledChannelDescription,
        defaultColor: const Color(0xFF6C63FF),
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ], debug: false);

    // Attach handlers
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// Compute the next DateTime instance for [hour]:[minute] in local time.
  DateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
      0,
      0,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Schedules exactly *one* notification for the next upcoming [hour]:[minute].
  /// The notification created has a payload with hour/minute so the background
  /// listener can reschedule the next day after the notification is displayed.
  Future<void> scheduleDailyAt({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Cancel any existing scheduled/active notification with this id first.
    await awesomeNotifications.cancel(id);

    // Compose payload so the background handler can reschedule the next day.
    final payload = {'hour': hour.toString(), 'minute': minute.toString()};

    final next = _nextInstanceOfTime(hour, minute);

    final schedule = NotificationCalendar.fromDate(
      date: next,
      preciseAlarm: true,
      allowWhileIdle: true,
      // repeats: false  -> default for fromDate is one-shot
    );

    await awesomeNotifications.createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.blue,
        backgroundColor: Colors.blue,
        icon: AppStrings.defaultIcon,
        payload: payload,
      ),
      schedule: schedule,
    );
  }

  /// Cancel specific schedule+notification by ID
  Future<void> cancelById(int id) async {
    await awesomeNotifications.cancel(id);
  }

  /// Cancel all scheduled notifications (careful: this is global)
  Future<void> cancelAllSchedules() async {
    await awesomeNotifications.cancelAllSchedules();
  }

  Future<void> cancelAll() async {
    await awesomeNotifications.cancelAll();
    await awesomeNotifications.dismissAllNotifications();
  }

  Future<bool> requestPermission() async {
    final allowed = await awesomeNotifications.isNotificationAllowed();
    if (allowed) return true;

    final granted = await awesomeNotifications
        .requestPermissionToSendNotifications(
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Vibration,
            NotificationPermission.Badge,
            NotificationPermission.PreciseAlarms,
          ],
        );
    return granted;
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification _,
  ) async {}

  /// This runs when the notification was displayed to the user.
  /// We use this to schedule the next day's notification (one-shot pattern).
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification received,
  ) async {
    try {
      // Only handle our daily reminder id
      if (received.id == AppConstants.dailyReminderId) {
        final payload = received.payload ?? {};
        final hour = int.tryParse(payload['hour'] ?? '') ?? 20;
        final minute = int.tryParse(payload['minute'] ?? '') ?? 0;

        // Compute next day's date/time
        final now = DateTime.now();
        var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
        // If the notification just displayed is for today's scheduled time,
        // schedule for tomorrow.
        scheduled = scheduled.add(const Duration(days: 1));

        final nextSchedule = NotificationCalendar.fromDate(
          date: scheduled,
          preciseAlarm: true,
          allowWhileIdle: true,
        );

        // Recreate notification for the next day (same id -> replaces previous)
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: AppConstants.dailyReminderId,
            channelKey: AppStrings.scheduledChannelKey,
            title: received.title ?? 'Trackedify Reminder',
            body: received.body ?? "Don't forget to add your expenses today.",
            notificationLayout: NotificationLayout.Default,
            payload: {'hour': hour.toString(), 'minute': minute.toString()},
            icon: AppStrings.defaultIcon,
          ),
          schedule: nextSchedule,
        );
      }
    } catch (_) {
      // Prevent background crash; fail silently
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction _) async {}

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction _) async {
    // * Navigating to the AddPage when any notification action is received
    // TODO : Doesn't work if app is not in background
    // ? so uncommented for now
    // MyApp.navigatorKey.currentState?.pushAndRemoveUntil(
    // MaterialPageRoute(builder: (context) => const AddPage()),
    // (route) => route.isFirst,
    // );
  }
}
