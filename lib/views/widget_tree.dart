import 'package:flutter/material.dart';
import 'package:spendle/data/notifiers.dart';
import 'package:spendle/shared/widgets/navbar_widget.dart';
import 'package:spendle/views/pages/home_page.dart';
import 'package:spendle/views/pages/stats_page.dart';
import 'package:spendle/views/pages/user_page.dart';

List<Widget> pages = [const HomePage(), const StatsPage(), const UserPage()];

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Spendle'), centerTitle: true),
      bottomNavigationBar: const NavBarWidget(),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
    );
  }
}
