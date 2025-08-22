import 'package:flutter/material.dart';
import 'package:spendle/data/notifiers.dart';
import 'package:spendle/shared/widgets/navbar_widget.dart';
import 'package:spendle/views/pages/home_page.dart';
import 'package:spendle/views/pages/stats_page.dart';
import 'package:spendle/views/pages/user_page.dart';
import 'package:spendle/views/pages/get_started_page.dart';
import 'package:spendle/database/database_helper.dart';

List<Widget> pages = [const HomePage(), const StatsPage(), const UserPage()];

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  bool isLoading = true;
  bool hasUser = false;

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    final db = await DatabaseHelper().database;
    final users = await db.query('user_info');

    setState(() {
      hasUser = users.isNotEmpty;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!hasUser) {
      return const GetStartedPage();
    }

    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300), // fade duration
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              // ensures proper widget identity for animation
              key: ValueKey<int>(selectedPage),
              child: pages[selectedPage],
            ),
          );
        },
      ),
      bottomNavigationBar: const NavBarWidget(),
    );
  }
}
