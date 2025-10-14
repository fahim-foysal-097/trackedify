import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackedify/services/auth_service.dart';
import 'package:trackedify/views/pages/set_pin_page.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _pinCtl = TextEditingController();
  String? _error;
  bool _isChecking = false;

  @override
  void dispose() {
    _pinCtl.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    final pin = _pinCtl.text.trim();
    final ok = await _auth.verifyPin(pin);

    if (!mounted) return;
    setState(() {
      _isChecking = false;
    });

    if (ok) {
      widget.onUnlocked();
    } else {
      if (!mounted) return;
      setState(() => _error = 'Incorrect PIN');
    }
  }

  Future<void> _forgotFlow() async {
    // Prompt user to enter recovery password
    final recovery = await showDialog<String?>(
      context: context,
      builder: (context) {
        final ctl = TextEditingController();
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: const Text('Recover PIN'),
          content: TextField(
            controller: ctl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter recovery password',
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ctl.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (!mounted || recovery == null || recovery.isEmpty) return;

    final ok = await _auth.verifyRecoveryPassword(recovery);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery password incorrect')),
      );
      return;
    }

    // recovery verified -> open SetPinPage to create new PIN
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SetPinPage(isChanging: true)),
    );
    if (!mounted) return;

    if (changed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed - please unlock again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Gradient using primary/secondary with slight opacity for dark/light balance
    final Gradient backgroundGradient = LinearGradient(
      colors: [cs.primary, cs.primaryContainer],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final cardColor = cs.surface;
    final cardElevationShadow = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.12);

    final iconCircleBg = cs.primaryContainer;
    final iconColor = cs.onPrimaryContainer;

    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurface.withValues(alpha: 0.7);

    final inputFill = cs.surfaceContainer.withValues(alpha: 0.85);
    final inputTextColor = cs.onSurface;

    final buttonColor = cs.primary;
    final buttonTextColor = cs.onPrimary;

    final linkColor = cs.primary;

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 12,
                      color: cardColor,
                      shadowColor: cardElevationShadow,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: iconCircleBg,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.onSurface.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.lock,
                                size: 72,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Unlock Trackedify',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your PIN to continue',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: _pinCtl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Enter PIN',
                                errorText: _error,
                                filled: true,
                                fillColor: inputFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              style: TextStyle(color: inputTextColor),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: _isChecking ? null : _submitPin,
                                child: _isChecking
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CupertinoActivityIndicator(
                                          color: buttonTextColor,
                                        ),
                                      )
                                    : Text(
                                        'Unlock',
                                        style: TextStyle(
                                          color: buttonTextColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _forgotFlow,
                              child: Text(
                                'Forgot PIN? Use recovery password',
                                style: TextStyle(
                                  color: linkColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
