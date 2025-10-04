import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/views/pages/about_page.dart';
import 'package:spendle/views/pages/settings/export_page.dart';
import 'package:spendle/views/pages/settings/import_page.dart';
import 'package:spendle/views/pages/settings_page.dart';
import 'package:spendle/services/update_service.dart';
import 'package:spendle/views/widget_tree.dart';
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

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadAppVersion();
  }

  void refresh() {
    loadUserInfo();
  }

  Future<void> loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        appVersion = info.version;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to read package info: $e');
    }
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
  }

  /// Pick an image and copy it into app documents for stable storage.
  Future<void> pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white),
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
      textColor: Colors.grey.shade700,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white),
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
        '''Tap the profile picture to edit and long-press to delete. Use the buttons below to export/import data, check for updates, and more. Also delete temporary downloaded updates to save space.''';

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

  @override
  Widget build(BuildContext context) {
    final imageProvider = _profileImageExists()
        ? FileImage(File(profilePicPath!)) as ImageProvider
        : const AssetImage('assets/img/pfp.jpg');

    // Color palette
    const gradientEnd = Color(0xFF6C5CE7);
    const gradientStart = Color(0xFF00B4D8);

    // Fixed tile height (pixels) - adjust for taller/shorter buttons.
    const double tileHeight = 64.0;

    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey("UserScroll"),
        child: Column(
          children: [
            // Top gradient header with curved bottom
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientStart.withValues(alpha: 0.25),
                    blurRadius: 24,
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
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.lightbulb,
                            color: Colors.white,
                          ),
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
                              backgroundColor: Colors.grey.shade200,
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    right: 4,
                                    bottom: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
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
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.black54,
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
                          style: KTextstyle.headerBlackText.copyWith(
                            color: Colors.black87,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Tip: Tap to change profile picture and long press to delete!",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
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

                  _buildActionTile(
                    icon: FontAwesomeIcons.fileImport,
                    label: 'Export',
                    accent: Colors.deepPurple,
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
                    accent: Colors.green,
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
                    icon: FontAwesomeIcons.trashArrowUp,
                    label: 'Clear Downloads',
                    accent: Colors.redAccent,
                    onTap: () async {
                      if (!mounted) return;
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
                      if (!mounted) return;
                      if (confirmed != true) return;

                      // run cleanup
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

                  _buildActionTile(
                    icon: FontAwesomeIcons.solidNoteSticky,
                    label: 'Release Notes',
                    accent: Colors.green,
                    onTap: () => _launchURL(
                      "https://fahim-foysal-097.github.io/spendle-website/releases.html",
                    ),
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.chrome,
                    label: 'Website',
                    accent: Colors.deepPurple,
                    onTap: () => _launchURL(
                      "https://fahim-foysal-097.github.io/spendle-website/",
                    ),
                  ),

                  _buildActionTile(
                    icon: FontAwesomeIcons.bug,
                    label: 'Report Bug',
                    accent: Colors.red,
                    onTap: () => _launchURL(
                      "https://github.com/fahim-foysal-097/Spendle/issues/new?template=bug_report.md",
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
                    appVersion.isNotEmpty ? 'Spendle v$appVersion' : 'Spendle',
                    style: TextStyle(color: Colors.grey.shade600),
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
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
