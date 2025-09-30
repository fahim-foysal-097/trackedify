import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/services/notification_service.dart';
import 'package:spendle/shared/constants/constants.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _notificationsEnabled = true;
  bool _loadingNotificationPref = true;

  late final NotificationUtil _notificationUtil;

  @override
  void initState() {
    super.initState();
    _notificationUtil = NotificationUtil(
      awesomeNotifications: AwesomeNotifications(),
    );
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final v = await DatabaseHelper().isNotificationEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = v;
      _loadingNotificationPref = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification'), centerTitle: true),
      body: _loadingNotificationPref
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _loadingNotificationPref
                      ? const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SwitchListTile(
                          title: const Text('Daily reminder at 8:00 PM'),
                          subtitle: const Text(
                            'Receive a daily add to review your expenses',
                          ),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.lightBlue,
                          value: _notificationsEnabled,
                          onChanged: (v) async {
                            await DatabaseHelper().setNotificationEnabled(v);
                            if (!mounted) return;
                            setState(() => _notificationsEnabled = v);

                            if (v) {
                              final granted = await _notificationUtil
                                  .requestPermission();
                              if (!granted) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notification permission denied',
                                    ),
                                  ),
                                );
                                await DatabaseHelper().setNotificationEnabled(
                                  false,
                                );
                                if (!mounted) return;
                                setState(() => _notificationsEnabled = false);
                                return;
                              }

                              await _notificationUtil.scheduleDailyAt(
                                id: AppConstants.dailyReminderId,
                                channelKey: AppStrings.scheduledChannelKey,
                                title: 'Spendle Reminder',
                                body:
                                    'Don\'t forget to add your expenses today.',
                                hour: 20,
                                minute: 00,
                              );

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Daily reminder enabled'),
                                ),
                              );
                            } else {
                              await _notificationUtil.cancelAllSchedules();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Daily reminder disabled'),
                                ),
                              );
                            }
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
