import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/shared/constants/icon_text_button.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/shared/widgets/avatar_widget.dart';
import 'package:spendle/shared/widgets/curvedbox_widget.dart';
import 'package:spendle/views/pages/about_page.dart';
import 'package:spendle/views/pages/settings_page.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key = const PageStorageKey("UserPage")});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        key: const PageStorageKey("UserScroll"),
        child: Column(
          children: [
            const Stack(children: [CurvedboxWidget3(), AvatarWidget()]),
            Container(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              alignment: Alignment.center,
              child: const Text("Functions", style: KTextstyle.headerBlackText),
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
