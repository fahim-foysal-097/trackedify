import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackedify/services/auth_service.dart';
import 'package:trackedify/views/pages/lock_screen.dart';
import 'package:trackedify/views/widget_tree.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _auth = AuthService();
  bool? _locked;

  @override
  void initState() {
    super.initState();
    _checkLocked();
    NavBarController.apply();
  }

  Future<void> _checkLocked() async {
    final pinSet = await _auth.isPinSet();
    if (!mounted) return;
    setState(() => _locked = pinSet);
  }

  void _onUnlocked() {
    setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_locked == null) {
      return const Scaffold(
        body: Center(child: CupertinoActivityIndicator(radius: 15)),
      );
    }

    if (_locked == true) {
      // show LockScreen; on unlock it calls onUnlocked -> show child
      NavBarController.apply();
      return LockScreen(onUnlocked: _onUnlocked);
    }

    // unlocked -> show the protected child
    return widget.child;
  }
}
