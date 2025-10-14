import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackedify/services/auth_service.dart';

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
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _pinCtl.dispose();
    _confirmCtl.dispose();
    _recoveryCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);

    final pin = _pinCtl.text.trim();
    final confirm = _confirmCtl.text.trim();
    final recovery = _recoveryCtl.text.trim();

    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() => _error = 'PIN must contain digits only.');
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
      setState(
        () => _error = 'Recovery password should be at least 6 characters.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _auth.setPin(pin, recoveryPassword: recovery);
      if (!mounted) return;
      // success
      if (widget.isChanging) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN changed')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('PIN set')));
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to save PIN: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isChanging ? 'Change PIN' : 'Set PIN';
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            tooltip: "Back",
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _pinCtl,
                keyboardType: TextInputType.number,
                obscureText: _obscure,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: widget.isChanging ? 'Enter new PIN' : 'Enter PIN',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmCtl,
                keyboardType: TextInputType.number,
                obscureText: _obscure,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Confirm PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _recoveryCtl,
                keyboardType: TextInputType.text,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Recovery password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: kToolbarHeight,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          widget.isChanging ? 'Change PIN' : 'Set PIN',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
