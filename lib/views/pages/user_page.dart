import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/theme_controller.dart';
import 'package:trackedify/views/pages/about_page.dart';
import 'package:trackedify/views/pages/settings/export_page.dart';
import 'package:trackedify/views/pages/settings/import_page.dart';
import 'package:trackedify/views/pages/settings/notification_settings.dart';
import 'package:trackedify/views/pages/settings_page.dart';
import 'package:trackedify/services/update_service.dart';
import 'package:trackedify/views/widget_tree.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key = const PageStorageKey("UserPage")});

  @override
  State<UserPage> createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  String username = "User";
  String? profilePicPath;
  bool showTip = false;
  int? userId;
  String appVersion = "";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadAppVersion();
  }

  void refresh() {
    loadUserInfo();
    loadAppVersion();
  }

  Future<void> loadAppVersion() async {
    setState(() {
      isLoading = true;
    });

    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        appVersion = info.version;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to read package info: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (kDebugMode) {
        debugPrint('Could not launch $url');
      }
    }
  }

  Future<void> loadUserInfo() async {
    setState(() {
      isLoading = true;
    });

    final db = await DatabaseHelper().database;
    final res = await db.query('user_info', limit: 1);

    if (res.isEmpty) {
      userId = await db.insert('user_info', {
        'username': 'User',
        'profile_pic': null,
        'user_tip_shown': 0,
      });
      profilePicPath = null;
      username = "User";
      showTip = true;
      if (!mounted) return;
      setState(() {});
      return;
    }

    final row = res.first;
    userId = row['id'] as int?;
    if (!mounted) return;
    setState(() {
      username = row['username'] as String? ?? "User";
      profilePicPath = row['profile_pic'] as String?;
      showTip = (row['user_tip_shown'] as int? ?? 0) == 0;
    });

    if (showTip && userId != null) {
      await db.update(
        'user_info',
        {'user_tip_shown': 1},
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  /// Pick an image and copy it into app documents for stable storage.
  Future<void> pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );
    if (!mounted) return;

    if (pickedFile != null && userId != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final picsDir = Directory(p.join(appDir.path, 'profile_pics'));
        if (!await picsDir.exists()) await picsDir.create(recursive: true);

        final ext = p.extension(pickedFile.path);
        final fileName = 'pfp_${DateTime.now().millisecondsSinceEpoch}$ext';
        final savedPath = p.join(picsDir.path, fileName);

        // copy picked file to app-local folder
        final savedFile = await File(pickedFile.path).copy(savedPath);

        profilePicPath = savedFile.path;
        final db = await DatabaseHelper().database;
        await db.update(
          'user_info',
          {'profile_pic': profilePicPath},
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (!mounted) return;
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: cs.error,
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: cs.onError),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save profile picture: $e')),
              ],
            ),
          ),
        );
      }
    }
  }

  /// Delete stored profile picture (also delete the file if it exists and is in app folder)
  Future<void> deleteProfilePicture() async {
    if (userId == null) return;

    final confirm = await PanaraConfirmDialog.show<bool>(
      context,
      title: "Delete?",
      message: "Are you sure you want to delete your profile picture?",
      confirmButtonText: "Delete",
      cancelButtonText: "Cancel",
      onTapCancel: () {
        Navigator.pop(context, false);
      },
      onTapConfirm: () {
        Navigator.pop(context, true);
      },
      textColor: Theme.of(context).textTheme.bodySmall?.color,
      panaraDialogType: PanaraDialogType.warning,
    );

    if (!mounted) return;
    if (confirm == true) {
      try {
        // if file exists and looks like an app-local file, delete it
        if (profilePicPath != null) {
          final f = File(profilePicPath!);
          if (await f.exists()) {
            // attempt delete, ignore errors
            try {
              await f.delete();
            } catch (_) {}
          }
        }

        profilePicPath = null;
        final db = await DatabaseHelper().database;
        await db.update(
          'user_info',
          {'profile_pic': null},
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (!mounted) return;
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: cs.error,
            content: Row(
              children: [
                Icon(Icons.warning_rounded, color: cs.onError),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to delete profile picture: $e')),
              ],
            ),
          ),
        );
      }
    }
  }

  bool _profileImageExists() {
    if (profilePicPath == null) return false;
    try {
      final f = File(profilePicPath!);
      return f.existsSync();
    } catch (_) {
      return false;
    }
  }

  void showTipsDialog() {
    const tips =
        '''Tap the profile picture to edit and long-press to delete. Use the buttons below to export/import data, check for updates, and more.''';

    PanaraInfoDialog.show(
      context,
      title: 'Hints & Tips',
      message: tips,
      buttonText: 'Got it',
      onTapDismiss: () => Navigator.pop(context),
      textColor: Theme.of(context).textTheme.bodySmall?.color,
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 12));
    }

    final imageProvider = _profileImageExists()
        ? FileImage(File(profilePicPath!)) as ImageProvider
        : const AssetImage('assets/img/pfp.jpg');

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ctrl = ThemeController.instance;
    final textMuted =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8) ?? Colors.grey;
    final shadowColor = theme.shadowColor.withValues(alpha: 0.16);

    // Fixed tile height (pixels) - adjust for taller/shorter buttons.
    const double tileHeight = 64.0;

    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey("UserScroll"),
        child: Column(
          children: [
            // Top header using theme primary gradient
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ctrl.effectiveColorForRole(context, 'user-container-1'),
                    ctrl.effectiveColorForRole(context, 'user-container-2'),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Small header row
                  Positioned(
                    top: 50,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        Text(
                          'Profile',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.lightbulb, color: cs.onPrimary),
                          onPressed: showTipsDialog,
                        ),
                      ],
                    ),
                  ),

                  // Avatar overlapping the header
                  Positioned(
                    bottom: -100,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: pickProfilePicture,
                          onLongPress: deleteProfilePicture,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 72,
                              backgroundImage: imageProvider,
                              backgroundColor: cs.surface,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    right: 4,
                                    bottom: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceBright,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          username,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),

            // Tip card (preserve logic)
            if (showTip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.lightbulb, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Tip: Tap to change profile picture and long press to delete!",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          onPressed: () => setState(() => showTip = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Buttons grid (modern pill cards) with fixed tile height
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: GridView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: tileHeight, // fixed height for each tile
                ),
                children: [
                  _buildActionTile(
                    icon: FontAwesomeIcons.gear,
                    label: 'Settings',
                    accent: Colors.blueAccent,
                    onTap: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      ).then((_) {
                        loadUserInfo();
                        NavBarController.apply();
                      });
                    },
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.trash,
                    label: 'Wipe Data',
                    accent: Colors.redAccent,
                    onTap: () {
                      if (!mounted) return;
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
                            setState(() {
                              profilePicPath = null;
                              username = "User";
                              showTip = true;
                            });
                            final cs2 = Theme.of(context).colorScheme;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: cs2.error,
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_rounded,
                                      color: cs2.onError,
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
                        textColor: Theme.of(context).textTheme.bodySmall?.color,
                        panaraDialogType: PanaraDialogType.error,
                      );
                    },
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.fileImport,
                    label: 'Export',
                    accent: cs.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => const ExportPage(),
                        ),
                      ).then((_) {
                        NavBarController.apply();
                      });
                    },
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.fileExport,
                    label: 'Import',
                    accent: cs.tertiary,
                    onTap: () {
                      PanaraConfirmDialog.show(
                        context,
                        title: "Import data from DB/JSON?",
                        message:
                            "This may replace all of your current data / append data (using JSON). Continue?",
                        textColor: Theme.of(context).textTheme.bodySmall?.color,
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

                  _buildActionTile(
                    icon: FontAwesomeIcons.download,
                    label: 'Check Update',
                    accent: Colors.blueAccent,
                    onTap: () async {
                      if (!mounted) return;
                      await UpdateService.checkForUpdate(
                        context,
                        manualCheck: true,
                      );
                    },
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.solidClock,
                    label: 'Daily Reminder',
                    accent: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const NotificationSettings(),
                        ),
                      ).then((_) {
                        NavBarController.apply();
                      });
                    },
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.solidNoteSticky,
                    label: 'Release Notes',
                    accent: Colors.green,
                    onTap: () => _launchURL(
                      "https://fahim-foysal-097.github.io/trackedify-website/releases.html",
                    ),
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.chrome,
                    label: 'Website',
                    accent: Colors.deepPurple,
                    onTap: () => _launchURL(
                      "https://fahim-foysal-097.github.io/trackedify-website/",
                    ),
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.bug,
                    label: 'Report Bug',
                    accent: Colors.red,
                    onTap: () => _launchURL(
                      "https://github.com/fahim-foysal-097/Trackedify/issues/new?template=bug_report.md",
                    ),
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.circleInfo,
                    label: 'About',
                    accent: Colors.lightBlue,
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

            const SizedBox(height: 28),

            // small footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appVersion.isNotEmpty
                        ? 'Trackedify v$appVersion'
                        : 'Trackedify',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    Color? accent,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final effectiveAccent = accent ?? cs.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: effectiveAccent.withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          // vertical padding kept small because tile height is fixed by grid mainAxisExtent
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: effectiveAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
