import 'package:flutter/material.dart';
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
          title: const Text('Recover PIN'),
          content: TextField(
            controller: ctl,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Recovery password'),
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

    if (!mounted) return;
    if (recovery == null || recovery.isEmpty) return;

    // verify
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
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: const Color(0xFFF6F6F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 72, color: Colors.blue),
                        const SizedBox(height: 12),
                        const Text(
                          'Unlock Spendle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter your PIN to continue',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pinCtl,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter PIN',
                            errorText: _error,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _isChecking ? null : _submitPin,
                            child: _isChecking
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Unlock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _forgotFlow,
                          child: const Text(
                            'Forgot PIN? Use recovery password',
                            style: TextStyle(color: Colors.blue),
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
    );
  }
}
