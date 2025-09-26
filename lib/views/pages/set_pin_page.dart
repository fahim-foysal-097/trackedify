import 'package:flutter/material.dart';
import 'package:spendle/services/auth_service.dart';

class SetPinPage extends StatefulWidget {
  final bool isChanging;
  const SetPinPage({super.key, this.isChanging = false});

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  final _pinCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _recoveryCtl = TextEditingController();
  final AuthService _auth = AuthService();

  bool _saving = false;
  bool _showPin = false;
  String? _error;

  @override
  void dispose() {
    _pinCtl.dispose();
    _confirmCtl.dispose();
    _recoveryCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
    });

    final pin = _pinCtl.text.trim();
    final confirm = _confirmCtl.text.trim();
    final recovery = _recoveryCtl.text.trim();

    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }

    if (pin != confirm) {
      setState(() => _error = 'PINs do not match.');
      return;
    }

    if (recovery.isEmpty) {
      setState(() => _error = 'Recovery password is required.');
      return;
    }

    if (recovery.length < 6) {
      setState(() => _error = 'Recovery pass should be at least 6 characters.');
      return;
    }

    setState(() => _saving = true);

    // persist securely
    await _auth.setPin(pin, recoveryPassword: recovery);

    if (!mounted) return; // guard against using context after await
    setState(() => _saving = false);

    // inform caller of success
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isChanging ? 'Change PIN' : 'Set PIN';
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _pinCtl,
                      keyboardType: TextInputType.number,
                      obscureText: !_showPin,
                      decoration: InputDecoration(
                        hintText: 'Enter new PIN',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPin ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _showPin = !_showPin),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmCtl,
                      keyboardType: TextInputType.number,
                      obscureText: !_showPin,
                      decoration: const InputDecoration(
                        hintText: 'Confirm PIN',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _recoveryCtl,
                      keyboardType: TextInputType.text,
                      obscureText: !_showPin,
                      decoration: const InputDecoration(
                        hintText: 'Recovery password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: kToolbarHeight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const CircularProgressIndicator()
                            : Text(
                                widget.isChanging ? 'Change PIN' : 'Set PIN',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
