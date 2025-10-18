import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/theme_controller.dart';
import 'package:trackedify/services/update_service.dart';
import 'package:trackedify/views/pages/about_page.dart';
import 'package:trackedify/views/pages/settings/edit_categories_page.dart';
import 'package:trackedify/views/pages/settings/export_page.dart';
import 'package:trackedify/views/pages/settings/import_page.dart';
import 'package:trackedify/views/pages/settings/change_username_page.dart';
import 'package:trackedify/views/pages/settings/notification_settings.dart';
import 'package:trackedify/views/pages/settings/security_settings.dart';
import 'package:trackedify/views/pages/settings/theme_settings.dart';
import 'package:trackedify/views/pages/settings/voice_commands_settings.dart';
import 'package:trackedify/views/widget_tree.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = ThemeController.instance;
    final iconColor = ctrl.effectiveColorForRole(context, 'primary');

    void showTipsDialog() {
      const tips =
          '''There are useful functions & settings like import/export here. You can also set daily reminders and app lock.''';

      PanaraInfoDialog.show(
        context,
        title: 'Hints & Tips',
        message: tips,
        buttonText: 'Got it',
        onTapDismiss: () => Navigator.pop(context),
        textColor: theme.textTheme.bodySmall?.color,
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
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
          ),
        ),
      );
    }

    Widget sectionCard(List<Widget> children) {
      return Card(
        color: cs.primary.withValues(alpha: 0.06),
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
          title: Text('Settings', style: theme.textTheme.titleLarge),
          centerTitle: false,
          leading: IconButton(
            tooltip: "Back",
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 25,
              color: cs.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actionsPadding: const EdgeInsets.only(right: 6),
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          actions: [
            IconButton(
              tooltip: 'Tips',
              icon: Icon(Icons.lightbulb_outline, color: cs.onSurface),
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
                  icon: Icons.color_lens_outlined,
                  title: 'Theme Settings',
                  iconColor: iconColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThemeSettingsPage(),
                      ),
                    ).then((_) {
                      NavBarController.apply();
                    });
                  },
                ),
                SettingsButton(
                  icon: Icons.tag,
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
                      textColor: theme.textTheme.bodySmall?.color,
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
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: cs.error,
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: cs.onError,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text('All data deleted'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      textColor: theme.textTheme.bodySmall?.color,
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
              ]),

              // --- Misc ---
              sectionTitle("More"),
              sectionCard([
                SettingsButton(
                  icon: Icons.open_in_new_rounded,
                  title: 'Visit Website',
                  iconColor: iconColor,
                  onTap: () => launchURL(
                    "https://fahim-foysal-097.github.io/trackedify-website/",
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
    final cs = Theme.of(context).colorScheme;

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
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
