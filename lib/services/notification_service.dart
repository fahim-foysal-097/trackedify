import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:spendle/shared/constants/constants.dart';

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

    // attach handlers
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  Future<void> scheduleDailyAt({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // cancel existing with same id
    await awesomeNotifications.cancel(id);

    final schedule = NotificationCalendar(
      hour: hour,
      minute: minute,
      second: 0,
      repeats: true,
      preciseAlarm: true,
    );

    await awesomeNotifications.createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.blue,
        backgroundColor: Colors.amber,
        icon: AppStrings.defaultIcon,
      ),
      schedule: schedule,
    );
  }

  Future<void> cancelAllSchedules() async {
    await awesomeNotifications.cancelAllSchedules();
    await awesomeNotifications.cancelAll();
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

            // for scheduled notifications
            NotificationPermission.PreciseAlarms,
          ],
        );
    return granted;
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification _,
  ) async {}

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification _,
  ) async {}

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction _) async {}

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction _) async {}
}
