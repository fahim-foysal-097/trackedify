import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spendle/data/notifiers.dart';

class NavBarWidget extends StatefulWidget {
  const NavBarWidget({super.key});

  @override
  State<NavBarWidget> createState() => _NavBarState();
}

class _NavBarState extends State<NavBarWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          height: 60,
          destinations: const [
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.house),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.chartColumn),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(FontAwesomeIcons.userGear),
              label: 'User',
            ),
          ],
          onDestinationSelected: (int value) {
            selectedPageNotifier.value = value;
          },
          selectedIndex: selectedPage,
        );
      },
    );
  }
}
