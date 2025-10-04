import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/services/notification_service.dart';
import 'package:spendle/shared/constants/constants.dart';
import 'package:panara_dialogs/panara_dialogs.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  bool _notificationsEnabled = true;
  bool _loading = true;
  bool _saving = false;

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
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool newValue) async {
    // Optimistically show spinner on control
    setState(() => _saving = true);

    // Save pref first
    await DatabaseHelper().setNotificationEnabled(newValue);

    if (!mounted) return;
    setState(() => _notificationsEnabled = newValue);

    if (newValue) {
      // Request permission
      final granted = await _notificationUtil.requestPermission();
      if (!granted) {
        // permission denied — revert pref
        await DatabaseHelper().setNotificationEnabled(false);
        if (!mounted) return;
        setState(() {
          _notificationsEnabled = false;
          _saving = false;
        });
        if (!mounted) return;
        PanaraInfoDialog.show(
          context,
          title: "Permission denied",
          message:
              "We couldn't get notification permission. Please enable it from system settings.",
          buttonText: "OK",
          textColor: Colors.black54,
          onTapDismiss: () => Navigator.pop(context),
          panaraDialogType: PanaraDialogType.normal,
        );
        return;
      }

      // Schedule daily notification at 20:00
      try {
        await _notificationUtil.scheduleDailyAt(
          id: AppConstants.dailyReminderId,
          channelKey: AppStrings.scheduledChannelKey,
          title: 'Spendle Reminder',
          body: 'Don\'t forget to add your expenses today.',
          hour: 20,
          minute: 0,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Daily reminder enabled')));
      } catch (e) {
        if (kDebugMode) debugPrint('Schedule failed: $e');
        await DatabaseHelper().setNotificationEnabled(false);
        if (!mounted) return;
        setState(() => _notificationsEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to schedule reminder')),
        );
      }
    } else {
      // Cancel schedules
      try {
        await _notificationUtil.cancelAllSchedules();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily reminder disabled')),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Cancel schedules failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel reminder')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  void _showTips() {
    PanaraInfoDialog.show(
      context,
      title: "Tips - Notifications",
      message:
          "Turn on daily reminders to get a quick nudge to add expenses. If notifications don't appear, check system permissions.",
      buttonText: "Got it",
      textColor: Colors.black54,
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            tooltip: 'Tips',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showTips,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF6F8FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications,
                            color: Colors.blue,
                          ),
                        ),
                        title: const Text(
                          'Daily reminder at 8:00 PM',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Receive a daily reminder to review/add expenses',
                        ),
                        trailing: _saving
                            ? const SizedBox(
                                width: 48,
                                height: 30,
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              )
                            : CupertinoSwitch(
                                value: _notificationsEnabled,
                                activeTrackColor: Colors.blue,
                                onChanged: (v) async {
                                  // confirm when disabling? small confirmation can be useful; here we toggle directly
                                  await _toggleNotifications(v);
                                },
                              ),
                        onTap: () async {
                          await _toggleNotifications(!_notificationsEnabled);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
