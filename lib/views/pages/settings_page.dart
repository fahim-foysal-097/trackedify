import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/services/update_service.dart';
import 'package:spendle/views/pages/about_page.dart';
import 'package:spendle/views/pages/settings/edit_categories_page.dart';
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

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    Widget sectionCard(List<Widget> children) {
      return Card(
        color: Colors.deepPurple.withValues(alpha: 0.07),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: Column(children: children),
      );
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
              // --- Profile & Personalization ---
              sectionTitle("Personalization"),
              sectionCard([
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
                  icon: Icons.label_outline_rounded,
                  title: 'Edit Categories',
                  iconColor: iconColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditCategoriesPage(),
                      ),
                    ).then((_) {
                      NavBarController.apply();
                    });
                  },
                ),
              ]),

              // --- Security & Controls ---
              sectionTitle("Security & Controls"),
              sectionCard([
                SettingsButton(
                  icon: Icons.lock_outline_rounded,
                  title: 'Security',
                  iconColor: iconColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SecuritySettings(),
                      ),
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
              ]),

              // --- Data Management ---
              sectionTitle("Data Management"),
              sectionCard([
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
                            builder: (BuildContext context) =>
                                const ImportPage(),
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
                  icon: Icons.delete_forever_outlined,
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
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red,
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(child: Text('All data deleted')),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      textColor: Colors.grey.shade700,
                      panaraDialogType: PanaraDialogType.error,
                    );
                  },
                ),
              ]),

              // --- Updates ---
              sectionTitle("Updates"),
              sectionCard([
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
                          "This will delete all temporary downloaded updates (safe). Continue?",
                      textColor: Colors.black54,
                      confirmButtonText: "Clear",
                      cancelButtonText: "Cancel",
                      onTapCancel: () => Navigator.pop(context, false),
                      onTapConfirm: () => Navigator.pop(context, true),
                      panaraDialogType: PanaraDialogType.warning,
                    );
                    if (!context.mounted) return;
                    if (confirmed != true) return;

                    final deleted = await UpdateService.clearDownloadFolder();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.deepPurple,
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Cleared $deleted file(s) from app download folder.",
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ]),

              // --- Misc ---
              sectionTitle("More"),
              sectionCard([
                SettingsButton(
                  icon: Icons.open_in_new_rounded,
                  title: 'Visit Website',
                  iconColor: iconColor,
                  onTap: () => launchURL(
                    "https://fahim-foysal-097.github.io/spendle-website/",
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
              ]),

              const SizedBox(height: 40),
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
    const double height = 54.0;
    const double iconSize = 26.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16)),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
