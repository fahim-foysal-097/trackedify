import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/services/update_service.dart';
import 'package:spendle/views/pages/about_page.dart';
import 'package:spendle/views/pages/settings/export_page.dart';
import 'package:spendle/views/pages/settings/import_page.dart';
import 'package:spendle/views/pages/settings/change_username_page.dart';
import 'package:spendle/views/pages/settings/notification_settings.dart';
import 'package:spendle/views/pages/settings/security_settings.dart';
import 'package:spendle/views/pages/settings/voice_commands_settings.dart';
import 'package:spendle/views/widget_tree.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const iconColor = Colors.deepPurple;

    void showTipsDialog() {
      const tips =
          '''There are useful functions & settings like import/export here. You can also set daily reminders and app lock. Also you should delete temporary downloaded updates to save space.''';

      PanaraInfoDialog.show(
        context,
        title: 'Hints & Tips',
        message: tips,
        buttonText: 'Got it',
        onTapDismiss: () => Navigator.pop(context),
        textColor: Colors.black54,
        panaraDialogType: PanaraDialogType.normal,
      );
    }

    Future<void> launchURL(String url) async {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (kDebugMode) {
          debugPrint('Could not launch $url');
        }
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
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
              onPressed: showTipsDialog,
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  ).then((_) {
                    NavBarController.apply();
                  });
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
                  ).then((_) {
                    NavBarController.apply();
                  });
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
                  ).then((_) {
                    NavBarController.apply();
                  });
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
                  ).then((_) {
                    NavBarController.apply();
                  });
                },
              ),
              SettingsButton(
                icon: Icons.file_upload_outlined,
                title: 'Export / Backup Data',
                iconColor: iconColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExportPage()),
                  ).then((_) {
                    NavBarController.apply();
                  });
                },
              ),
              SettingsButton(
                icon: Icons.file_download_outlined,
                title: 'Import / Restore Data',
                iconColor: iconColor,
                onTap: () {
                  PanaraConfirmDialog.show(
                    context,
                    title: "Import data from DB/JSON?",
                    message:
                        "This may replace all of your current data / append data (using JSON). Continue?",
                    textColor: Colors.black54,
                    confirmButtonText: "Confirm",
                    cancelButtonText: "Cancel",
                    onTapCancel: () => Navigator.pop(context),
                    onTapConfirm: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => const ImportPage(),
                        ),
                      ).then((_) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        NavBarController.apply();
                      });
                    },
                    panaraDialogType: PanaraDialogType.error,
                  );
                },
              ),
              SettingsButton(
                icon: Icons.cloud_download_outlined,
                title: 'Check For Update',
                iconColor: iconColor,
                onTap: () async {
                  if (!context.mounted) return;
                  await UpdateService.checkForUpdate(
                    context,
                    manualCheck: true,
                  );
                },
              ),
              SettingsButton(
                icon: Icons.delete_outline,
                title: 'Clear Downloaded Updates',
                iconColor: iconColor,
                onTap: () async {
                  if (!context.mounted) return;
                  final confirmed = await PanaraConfirmDialog.show<bool>(
                    context,
                    title: "Clear downloads?",
                    message:
                        "This will delete all temporary downloaded updates. Continue?",
                    textColor: Colors.black54,
                    confirmButtonText: "Clear",
                    cancelButtonText: "Cancel",
                    onTapCancel: () => Navigator.pop(context, false),
                    onTapConfirm: () => Navigator.pop(context, true),
                    panaraDialogType: PanaraDialogType.warning,
                  );
                  if (!context.mounted) return;
                  if (confirmed != true) return;

                  // run cleanup
                  final deleted = await UpdateService.clearDownloadFolder();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Cleared $deleted file(s) from app download folder.",
                      ),
                    ),
                  );
                },
              ),
              SettingsButton(
                icon: Icons.file_upload_outlined,
                title: 'Delete All Data',
                iconColor: iconColor,
                onTap: () {
                  if (!context.mounted) return;
                  PanaraConfirmDialog.show(
                    context,
                    title: "Wipe Data?",
                    message: "Are you sure you want to delete all data?",
                    confirmButtonText: "Delete",
                    cancelButtonText: "Cancel",
                    onTapCancel: () {
                      Navigator.pop(context);
                    },
                    onTapConfirm: () async {
                      await DatabaseHelper().wipeAllData();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("All data deleted!")),
                        );
                      }
                    },
                    textColor: Colors.grey.shade700,
                    panaraDialogType: PanaraDialogType.error,
                  );
                },
              ),
              SettingsButton(
                icon: Icons.open_in_new_rounded,
                title: 'Visit Website',
                iconColor: iconColor,
                onTap: () => launchURL(
                  "https://fahim-foysal-097.github.io/spendle-website/releases.html",
                ),
              ),
              SettingsButton(
                icon: Icons.info,
                title: 'About',
                iconColor: iconColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => const AboutPage(),
                    ),
                  ).then((_) {
                    NavBarController.apply();
                  });
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
    const double leftPadding = 16;
    const double rightPadding = 14;

    return Column(
      children: [
        Material(
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

                  Icon(
                    Icons.chevron_right_rounded,
                    size: 30,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
