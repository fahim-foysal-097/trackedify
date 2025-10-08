import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/notification_service.dart';
import 'package:trackedify/shared/constants/constants.dart';
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
  int _hour = 20;
  int _minute = 0;

  @override
  void initState() {
    super.initState();
    _notificationUtil = NotificationUtil(
      awesomeNotifications: AwesomeNotifications(),
    );
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final enabled = await DatabaseHelper().isNotificationEnabled();
    final time = await DatabaseHelper().getNotificationTime();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _hour = time['hour'] ?? 20;
      _minute = time['minute'] ?? 0;
      _loading = false;
    });
  }

  Future<void> _toggleNotifications(bool newValue) async {
    setState(() => _saving = true);

    await DatabaseHelper().setNotificationEnabled(newValue);

    if (!mounted) return;
    setState(() => _notificationsEnabled = newValue);

    if (newValue) {
      final granted = await _notificationUtil.requestPermission();
      if (!granted) {
        await DatabaseHelper().setNotificationEnabled(false);
        if (!mounted) return;
        setState(() {
          _notificationsEnabled = false;
          _saving = false;
        });
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

      try {
        final time = await DatabaseHelper().getNotificationTime();
        final h = time['hour'] ?? 20;
        final m = time['minute'] ?? 0;

        // scheduleDailyAt will cancel any existing noti with the same id and create the next one-shot instance.
        await _notificationUtil.scheduleDailyAt(
          id: AppConstants.dailyReminderId,
          channelKey: AppStrings.scheduledChannelKey,
          title: 'Trackedify Reminder',
          body: 'Don\'t forget to add your expenses today.',
          hour: h,
          minute: m,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Daily reminder enabled')),
              ],
            ),
          ),
        );
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
      // Cancel by ID
      try {
        await _notificationUtil.cancelById(AppConstants.dailyReminderId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Daily reminder disabled')),
              ],
            ),
          ),
        );
      } catch (e) {
        if (kDebugMode) debugPrint('Cancel failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel reminder: $e ')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$h12:$mm $period';
  }

  Future<void> _pickTime() async {
    final initial = TimeOfDay(hour: _hour, minute: _minute);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      await DatabaseHelper().setNotificationTime(picked.hour, picked.minute);
      if (!mounted) return;
      setState(() {
        _hour = picked.hour;
        _minute = picked.minute;
      });

      // Cancel existing scheduled instance and reschedule next one-shot for the new time.
      await _notificationUtil.cancelById(AppConstants.dailyReminderId);

      if (_notificationsEnabled) {
        final granted = await _notificationUtil.requestPermission();
        if (granted) {
          await _notificationUtil.scheduleDailyAt(
            id: AppConstants.dailyReminderId,
            channelKey: AppStrings.scheduledChannelKey,
            title: 'Trackedify Reminder',
            body: 'Don\'t forget to add your expenses today.',
            hour: _hour,
            minute: _minute,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.deepPurple,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reminder set for ${_formatTime(_hour, _minute)}',
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          await DatabaseHelper().setNotificationEnabled(false);
          if (!mounted) return;
          setState(() => _notificationsEnabled = false);
          PanaraInfoDialog.show(
            context,
            title: "Permission denied",
            message:
                "We couldn't get notification permission. Reminder disabled. Please enable notifications in system settings to use reminders.",
            buttonText: "OK",
            textColor: Colors.black54,
            onTapDismiss: () => Navigator.pop(context),
            panaraDialogType: PanaraDialogType.normal,
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reminder time saved: ${_formatTime(_hour, _minute)}',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to save/pick time: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to save reminder time: $e')),
            ],
          ),
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showTips() {
    PanaraInfoDialog.show(
      context,
      title: "Tips - Notifications",
      message:
          "Turn on daily reminders to get a quick reminder to add expenses. If notifications don't appear, check system permissions.",
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
                      child: Column(
                        children: [
                          ListTile(
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
                            title: Text(
                              'Daily reminder at ${_formatTime(_hour, _minute)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                                      await _toggleNotifications(v);
                                    },
                                  ),
                            onTap: () async {
                              await _toggleNotifications(
                                !_notificationsEnabled,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Reminder time',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(_hour, _minute),
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _saving
                                    ? null
                                    : () async {
                                        await _pickTime();
                                      },
                                icon: const Icon(Icons.edit_calendar_outlined),
                                label: const Text('Change'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
