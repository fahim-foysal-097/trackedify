import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spendle/data/notifiers.dart';
import 'package:spendle/shared/constants/constants.dart';

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bg = Colors.blue;
    const Color selectedIconColor = Colors.white;
    final Color unselectedIconColor = Colors.white.withValues(alpha: 0.65);

    // gap width reserved for the FAB (slightly larger than diameter so it breathes)
    const double gapWidth = FabConfig.fabDiameter * 1.1;

    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: BottomAppBar(
            elevation: 6,
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 64,
                color: bg,
                child: Row(
                  children: [
                    // left side items
                    _navItem(
                      icon: FontAwesomeIcons.solidHouse,
                      label: 'Home',
                      selected: selectedPage == 0,
                      selectedColor: selectedIconColor,
                      unselectedColor: unselectedIconColor,
                      onTap: () => selectedPageNotifier.value = 0,
                    ),
                    _navItem(
                      icon: FontAwesomeIcons.chartPie,
                      label: 'Stats',
                      selected: selectedPage == 1,
                      selectedColor: selectedIconColor,
                      unselectedColor: unselectedIconColor,
                      onTap: () => selectedPageNotifier.value = 1,
                    ),

                    // spacer for FAB / middle gap
                    const SizedBox(width: gapWidth),

                    // right side items
                    _navItem(
                      icon: FontAwesomeIcons.chartSimple,
                      label: 'Charts',
                      selected: selectedPage == 2,
                      selectedColor: selectedIconColor,
                      unselectedColor: unselectedIconColor,
                      onTap: () => selectedPageNotifier.value = 2,
                    ),
                    _navItem(
                      icon: FontAwesomeIcons.solidUser,
                      label: 'User',
                      selected: selectedPage == 3,
                      selectedColor: selectedIconColor,
                      unselectedColor: unselectedIconColor,
                      onTap: () => selectedPageNotifier.value = 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// helper to build a nav item. Uses InkWell so ripples are visible.
  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required Color selectedColor,
    required Color unselectedColor,
    required VoidCallback onTap,
  }) {
    final color = selected ? selectedColor : unselectedColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
