import 'package:flutter/material.dart';
import 'package:spendle/data/notifiers.dart';
import 'package:spendle/shared/constants/constants.dart';
import 'package:spendle/shared/widgets/navbar_widget.dart';
import 'package:spendle/views/pages/home_page.dart';
import 'package:spendle/views/pages/insights_page.dart';
import 'package:spendle/views/pages/stats_page.dart';
import 'package:spendle/views/pages/user_page.dart';
import 'package:spendle/views/pages/add_page.dart';
import 'package:spendle/views/pages/onboarding_page.dart';
import 'package:spendle/database/database_helper.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  final homeKey = GlobalKey<HomePageState>();
  final statsKey = GlobalKey<StatsPageState>();
  final insightKey = GlobalKey<InsightsPageState>();
  final userKey = GlobalKey<UserPageState>();

  late final List<Widget> pages = [
    // global keys for the pages to refresh
    HomePage(key: homeKey),
    StatsPage(key: statsKey),
    InsightsPage(key: insightKey),
    UserPage(key: userKey),
  ];

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
      return const OnboardingPage();
    }

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 25),
        width: FabConfig.fabDiameter,
        height: FabConfig.fabDiameter,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: FloatingActionButton(
          onPressed: () {
            // open AddPage; handle post-pop logic (refresh) inside then(...) if needed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPage()),
            ).then((_) {
              // After coming back, refresh the current page
              final idx = selectedPageNotifier.value;
              if (idx == 0) homeKey.currentState?.refresh();
              if (idx == 1) statsKey.currentState?.refreshAll();
              if (idx == 2) insightKey.currentState?.refresh();
              if (idx == 3) userKey.currentState?.refresh();
            });
          },
          elevation: 7,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 3, color: Colors.blue),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            width: FabConfig.fabDiameter,
            height: FabConfig.fabDiameter,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),

      body: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      bottomNavigationBar: const NavBarWidget(),
    );
  }
}
