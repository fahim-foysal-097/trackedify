import 'package:flutter/material.dart';
import 'package:spendle/views/pages/settings/change_username_page.dart';
import 'package:spendle/views/pages/settings/notification_settings.dart';
import 'package:spendle/views/pages/settings/security_settings.dart';
import 'package:spendle/views/pages/settings/voice_commands_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.deepPurple;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              SettingsButton(
                icon: Icons.person_outline,
                title: 'Change Your Username',
                iconColor: iconColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangeUsernamePage(),
                    ),
                  );
                },
              ),
              SettingsButton(
                icon: Icons.lock_outline_rounded,
                title: 'Security',
                iconColor: iconColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SecuritySettings()),
                  );
                },
              ),
              SettingsButton(
                icon: Icons.mic_none_outlined,
                title: 'Voice Commands',
                iconColor: iconColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VoiceCommandsSettings(),
                    ),
                  );
                },
              ),
              SettingsButton(
                icon: Icons.access_alarms_rounded,
                title: 'Daily Reminder',
                iconColor: iconColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettings(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;

  const SettingsButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const double height = 48.0;
    const double iconSize = 28.0;
    const double leftPadding = 12;
    const double rightPadding = 12;
    const double topPadding = 4;
    const double bottomPadding = 4;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Container(
          height: height,
          padding: const EdgeInsets.only(
            left: leftPadding,
            right: rightPadding,
            top: topPadding,
            bottom: bottomPadding,
          ),

          child: Row(
            children: [
              Center(
                child: Icon(icon, color: iconColor, size: iconSize),
              ),

              const SizedBox(width: 10),

              // Title text
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    // fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              // Trailing chevron pushed slightly toward the right by container right padding
              Icon(Icons.chevron_right, size: 30, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
