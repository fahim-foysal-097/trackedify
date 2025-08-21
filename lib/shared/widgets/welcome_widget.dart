import 'package:flutter/material.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/views/pages/settings_page.dart';
import 'package:spendle/database/database_helper.dart';

class WelcomeWidget extends StatefulWidget {
  const WelcomeWidget({super.key});

  @override
  State<WelcomeWidget> createState() => _WelcomeWidgetState();
}

class _WelcomeWidgetState extends State<WelcomeWidget> {
  String username = "User"; // default value

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('user_info');

    if (result.isNotEmpty) {
      setState(() {
        username = result.first['username'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 100, 0, 0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const SettingsPage();
                  },
                ),
              ).then((_) {
                // Refresh username when coming back from settings
                _loadUsername();
              });
            },
            child: const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 15, 22, 0),
                child: Icon(Icons.settings, size: 30, color: Colors.white),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text('Welcome back,', style: KTextstyle.smallHeaderText),
              Text(username, style: KTextstyle.headerText),
            ],
          ),
        ],
      ),
    );
  }
}
