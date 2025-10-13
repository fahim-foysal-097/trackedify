import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackedify/views/pages/settings_page.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/views/widget_tree.dart';

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
    final cs = Theme.of(context).colorScheme;
    final onPrimary = cs.onPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 120, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onPrimary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                username,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
            ],
          ),
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
                NavBarController.apply();
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(FontAwesomeIcons.gear, color: onPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
