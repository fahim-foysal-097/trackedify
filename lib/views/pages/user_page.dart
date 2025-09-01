import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/constants/icon_text_button.dart';
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
      setState(() {});
      return;
    }

    final row = res.first;
    userId = row['id'] as int?;
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

  Future<void> pickProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && userId != null) {
      profilePicPath = pickedFile.path;
      final db = await DatabaseHelper().database;
      await db.update(
        'user_info',
        {'profile_pic': profilePicPath},
        where: 'id = ?',
        whereArgs: [userId],
      );
      setState(() {});
    }
  }

  Future<void> deleteProfilePicture() async {
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Profile Picture?"),
        content: const Text(
          "Are you sure you want to delete your profile picture?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      profilePicPath = null;
      final db = await DatabaseHelper().database;
      await db.update(
        'user_info',
        {'profile_pic': null},
        where: 'id = ?',
        whereArgs: [userId],
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            radius: 120,
                            backgroundImage: profilePicPath != null
                                ? FileImage(File(profilePicPath!))
                                : const AssetImage('assets/img/pfp.jpg')
                                      as ImageProvider,
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
              padding: const EdgeInsets.fromLTRB(10, 20, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTextButton(
                    Icons.settings,
                    "Settings",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                  IconTextButton(
                    Icons.delete_forever,
                    "Wipe Data",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog.adaptive(
                            title: const Text("Wipe Data?"),
                            content: const Text(
                              "Are you sure you want to delete all data?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
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
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  IconTextButton(
                    Icons.info,
                    "About",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
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
