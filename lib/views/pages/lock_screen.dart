import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spendle/services/auth_service.dart';
import 'package:spendle/views/pages/set_pin_page.dart';

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
        return AlertDialog(
          backgroundColor: Colors.purple[40],
          title: const Text('Recover PIN'),
          content: TextField(
            controller: ctl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter recovery password',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
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
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
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
                      color: Colors.white.withValues(alpha: 0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 72,
                                color: Color(0xFF6A11CB),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Unlock Spendle',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Enter your PIN to continue',
                              style: TextStyle(
                                color: Colors.grey,
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
                                fillColor: Colors.purple[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A11CB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: _isChecking ? null : _submitPin,
                                child: _isChecking
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Unlock',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _forgotFlow,
                              child: const Text(
                                'Forgot PIN? Use recovery password',
                                style: TextStyle(
                                  color: Color(0xFF6A11CB),
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
