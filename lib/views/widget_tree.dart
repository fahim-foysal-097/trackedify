import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackedify/data/notifiers.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/theme_controller.dart';
import 'package:trackedify/shared/constants/constants.dart';
import 'package:trackedify/shared/widgets/navbar_widget.dart';
import 'package:trackedify/views/pages/add_expense_page.dart';
import 'package:trackedify/views/pages/home_page.dart';
import 'package:trackedify/views/pages/insights_page.dart';
import 'package:trackedify/views/pages/onboarding_page.dart';
import 'package:trackedify/views/pages/stats_page.dart';
import 'package:trackedify/views/pages/user_page.dart';

class NavBarController {
  static Future<void> apply() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top], // status bar only
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  static Future<void> restore() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> with WidgetsBindingObserver {
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

  Timer? _reapplyTimer; // used for small reapply delays
  Timer? _autoHideTimer; // scheduled hide when user reveals nav

  // sensible delay constant (tweak if needed)
  static const Duration _reapplyDelay = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Immediately apply desired system UI. Then ensure again after first frame and after a short delay.
    NavBarController.apply();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => NavBarController.apply(),
    );

    // fallback short reapply to handle OEM races
    _reapplyTimer?.cancel();
    _reapplyTimer = Timer(_reapplyDelay, NavBarController.apply);

    // ensure nav is kept hidden when switching bottom tabs
    selectedPageNotifier.addListener(_onSelectedPageChanged);

    _checkUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    selectedPageNotifier.removeListener(_onSelectedPageChanged);

    _reapplyTimer?.cancel();
    _autoHideTimer?.cancel();

    // Restore system UI on dispose so app doesn't remain in custom mode.
    NavBarController.restore();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reapply when app resumes so nav hides again after user interactions or OS events.
    if (state == AppLifecycleState.resumed) {
      _reapplyTimer?.cancel();
      _reapplyTimer = Timer(_reapplyDelay, NavBarController.apply);
    }
  }

  Future<void> _checkUser() async {
    try {
      final db = await DatabaseHelper().database;
      final users = await db.query('user_info');

      if (!mounted) return;
      setState(() {
        hasUser = users.isNotEmpty;
        isLoading = false;
      });
    } catch (e) {
      // DB failed
      if (kDebugMode) {
        debugPrint('checking User error from widget tree: $e');
      }
      if (!mounted) return;
      setState(() {
        hasUser = false;
        isLoading = false;
      });
    }
  }

  void _scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), NavBarController.apply);
  }

  void _onSelectedPageChanged() {
    // When user switches tabs, reapply UI rules to ensure nav remains hidden.
    NavBarController.apply();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CupertinoActivityIndicator(radius: 15)),
      );
    }

    if (!hasUser) return const OnboardingPage();

    final ctrl = ThemeController.instance;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // If pointer is near the bottom edge, schedule re-hiding of nav after 3s.
        if (event.position.dy >= MediaQuery.of(context).size.height - 120) {
          _scheduleAutoHide();
        }
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: TweenAnimationBuilder<double>(
          key: const ValueKey('fab_animation'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: child,
            );
          },
          child: SizedBox(
            width: FabConfig.fabDiameter,
            height: FabConfig.fabDiameter,
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AddPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            ),
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ).then((_) {
                  // After coming back, refresh the current page
                  final idx = selectedPageNotifier.value;
                  if (idx == 0) homeKey.currentState?.refresh();
                  if (idx == 1) statsKey.currentState?.refreshAll();
                  if (idx == 2) insightKey.currentState?.refresh();
                  if (idx == 3) userKey.currentState?.refresh();

                  // reapply navrules after coming back
                  NavBarController.apply();
                });
              },
              elevation: 7,
              backgroundColor: ctrl.effectiveColorForRole(context, 'fab-bg'),
              shape: CircleBorder(
                side: BorderSide(
                  width: 3,
                  color: ctrl.effectiveColorForRole(context, 'nav'),
                ),
              ),
              child: Icon(
                Icons.add,
                size: 28,
                color: ctrl.effectiveColorForRole(context, 'nav'),
              ),
            ),
          ),
        ),

        body: ValueListenableBuilder<int>(
          valueListenable: selectedPageNotifier,
          builder: (context, selectedPage, child) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.15, 0.0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                );
              },
              child: IndexedStack(
                key: ValueKey<int>(selectedPage),
                index: selectedPage,
                children: pages,
              ),
            );
          },
        ),
        bottomNavigationBar: const NavBarWidget(),
      ),
    );
  }
}
