import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:spendle/data/notifiers.dart';

class NavBarWidget extends StatefulWidget {
  const NavBarWidget({super.key});

  @override
  State<NavBarWidget> createState() => _NavBarState();
}

class _NavBarState extends State<NavBarWidget> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return SizedBox(
          height: 60,
          child: SalomonBottomBar(
            currentIndex: selectedPage,
            selectedItemColor: const Color(0xff6200ee),
            unselectedItemColor: const Color(0xff757575),
            onTap: (index) {
              selectedPageNotifier.value = index;
            },
            items: [
              SalomonBottomBarItem(
                icon: const Icon(FontAwesomeIcons.houseChimney),
                title: const Text('Home'),
                selectedColor: Colors.purple,
              ),
              SalomonBottomBarItem(
                icon: const Icon(FontAwesomeIcons.chartSimple),
                title: const Text('Stats'),
                selectedColor: Colors.pink,
              ),
              SalomonBottomBarItem(
                icon: const Icon(FontAwesomeIcons.solidAddressCard),
                title: const Text('User'),
                selectedColor: Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }
}
