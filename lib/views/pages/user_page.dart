import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/constants/styled_button.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/shared/widgets/curvedbox_widget.dart';
import 'package:spendle/views/pages/about_page.dart';
import 'package:spendle/views/pages/settings_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key = const PageStorageKey("UserPage")});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String username = "User";
  String? profilePicPath;
  bool showTip = false;
  int? userId;

  // prevent concurrent import/export
  bool _isProcessingDb = false;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
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
          SnackBar(content: Text('Failed to save profile picture: $e')),
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
          SnackBar(content: Text('Failed to delete profile picture: $e')),
        );
      }
    }
  }

  // Export DB - user picks directory
  Future<void> exportDb() async {
    if (_isProcessingDb || !mounted) return;
    setState(() => _isProcessingDb = true);

    bool dialogShown = false;
    try {
      // show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;

      // get source DB path via public helper
      final dbPath = await DatabaseHelper().getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        // close spinner if shown
        if (dialogShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          dialogShown = false;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Database file not found.")),
        );
        return;
      }

      // default filename
      final now = DateTime.now();
      final timestamp =
          '${now.year.toString()}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}-T-'
          '${now.hour.toString().padLeft(2, '0')}-'
          '${now.minute.toString().padLeft(2, '0')}';
      final defaultFileName = 'expense_backup_$timestamp.db';

      // Use SAF save dialog to let user pick destination (works on Android 11+)
      final params = SaveFileDialogParams(
        sourceFilePath: dbFile.path,
        fileName: defaultFileName,
      );

      final savedPath = await FlutterFileDialog.saveFile(params: params);

      // close spinner
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (!mounted) return;

      if (savedPath == null) {
        // user cancelled the save dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Export cancelled.")));
      } else {
        // savedPath might be a content:// URI (Android SAF) or a file path.
        final bool isContentUri = savedPath.startsWith('content://');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isContentUri
                  ? 'Database exported successfully (SAF URI). You can open it from your Files app.'
                  : 'Database exported to: $savedPath',
            ),
          ),
        );
      }
    } catch (e) {
      // ensure dialog is closed on error
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    } finally {
      if (mounted) setState(() => _isProcessingDb = false);
    }
  }

  // Import DB - user picks file
  Future<void> importDb() async {
    if (_isProcessingDb || !mounted) return;
    setState(() => _isProcessingDb = true);

    bool dialogShown = false;
    try {
      // let user pick .db file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (!mounted) return;

      if (result == null || result.files.single.path == null) {
        // user cancelled file picker
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Import cancelled.")));
        return;
      }

      // show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShown = true;

      final importPath = result.files.single.path!;
      final importFile = File(importPath);

      if (!await importFile.exists()) {
        if (dialogShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          dialogShown = false;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected file does not exist.")),
        );
        return;
      }

      // do the import
      await DatabaseHelper().importDatabase(importPath);

      // close DB if needed, then reload
      await DatabaseHelper().closeDatabase();
      await loadUserInfo();

      if (!mounted) return;
      // close spinner
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Database imported successfully!")),
      );
    } catch (e) {
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Import failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessingDb = false);
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

  @override
  Widget build(BuildContext context) {
    final imageProvider = _profileImageExists()
        ? FileImage(File(profilePicPath!)) as ImageProvider
        : const AssetImage('assets/img/pfp.jpg');

    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey("UserScroll"),
        child: Column(
          children: [
            Stack(
              children: [
                const CurvedboxWidget3(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 150, 0, 0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickProfilePicture,
                        onLongPress: deleteProfilePicture,
                        child: Container(
                          alignment: Alignment.center,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  71,
                                  90,
                                  100,
                                ).withValues(alpha: 0.2),
                                spreadRadius: 2,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 80,
                            backgroundImage: imageProvider,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (showTip)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            color: Colors.lightBlue.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.lightbulb,
                                color: Colors.blue,
                              ),
                              title: const Text(
                                "Tip: Tap to change profile picture and long press to delete!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => showTip = false),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              alignment: Alignment.center,
              child: Text(username, style: KTextstyle.headerBlackText),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  styledButton(
                    icon: FontAwesomeIcons.gear,
                    text: "Settings",
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  styledButton(
                    icon: FontAwesomeIcons.trash,
                    text: "Wipe Data",
                    iconColor: Colors.redAccent,
                    onPressed: () {
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
                                content: Text("All data deleted!"),
                              ),
                            );
                          }
                        },
                        textColor: Colors.grey.shade700,
                        panaraDialogType: PanaraDialogType.error,
                      );
                    },
                  ),
                  styledButton(
                    icon: FontAwesomeIcons.upload,
                    text: "Export Database",
                    iconColor: Colors.green,
                    onPressed: () {
                      if (_isProcessingDb) return;
                      exportDb();
                    },
                  ),
                  styledButton(
                    icon: FontAwesomeIcons.download,
                    text: "Import Database",
                    iconColor: Colors.deepPurple,
                    onPressed: () {
                      if (_isProcessingDb) return;
                      importDb();
                    },
                  ),
                  styledButton(
                    icon: FontAwesomeIcons.circleInfo,
                    text: "About",
                    iconColor: Colors.orange,
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
