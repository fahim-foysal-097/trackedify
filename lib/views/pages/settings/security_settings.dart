import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/services/auth_service.dart';
import 'package:spendle/views/pages/set_pin_page.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  final AuthService _auth = AuthService();

  bool _loadingAuthState = true;
  bool _pinSet = false;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final pinSet = await _auth.isPinSet();
    if (!mounted) return;
    setState(() {
      _pinSet = pinSet;
      _loadingAuthState = false;
    });
  }

  Future<String?> _promptForPin({required String title}) async {
    // prompt for PIN
    if (!mounted) return null;
    final ctl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
        ),
        content: TextField(
          controller: ctl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ctl.text.trim()),
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return null;
    return result;
  }

  Future<void> _enableAppLock() async {
    // If no PIN set, go to SetPinPage
    if (!_pinSet) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetPinPage(isChanging: false)),
      );
      if (!mounted) return;
      if (result == true) {
        await _loadAuthState();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('App lock enabled')));
      }
      return;
    }
    // Already set
    if (!mounted) return;
    setState(() => _pinSet = true);
  }

  Future<void> _disableAppLock() async {
    final res = await _promptForPin(title: 'Confirm to disable app lock');
    if (!mounted) return;
    if (res == null || res.isEmpty) return;
    final ok = await _auth.verifyPin(res);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
      return;
    }
    await _auth.disablePin();
    if (!mounted) return;
    await _loadAuthState();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App lock disabled')));
  }

  Future<void> _changePin() async {
    // require current PIN first
    final res = await _promptForPin(title: 'Confirm to change PIN');

    if (!mounted) return;

    if (res == null || res.isEmpty) return;

    final ok = await _auth.verifyPin(res);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
      return;
    }

    // open SetPinPage
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SetPinPage(isChanging: true)),
    );
    if (!mounted) return;
    if (changed == true) {
      await _loadAuthState();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN changed')));
    }
  }

  Future<void> _setRecoveryPassword() async {
    final pinCtl = TextEditingController();

    // Ask for current PIN
    final currentPin = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify PIN'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
        ),
        content: TextField(
          controller: pinCtl,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter current PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(pinCtl.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (!mounted || currentPin == null || currentPin.isEmpty) return;

    // Verify the PIN
    final isValid = await _auth.verifyPin(currentPin);
    if (!mounted) return;
    if (!isValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
      return;
    }

    // Ask for new recovery password
    if (!mounted) return;
    final recoveryCtl = TextEditingController();
    final newRecovery = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set new recovery password'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
        ),
        content: TextField(
          controller: recoveryCtl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter new recovery password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(recoveryCtl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || newRecovery == null || newRecovery.isEmpty) return;

    // Save recovery password
    await _auth.setRecoveryPassword(newRecovery);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recovery password saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security'), centerTitle: true),
      body: _loadingAuthState
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Security',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  // show confirmation modal before toggling
                  SwitchListTile(
                    title: const Text('Enable App Lock (PIN)'),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade400,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.lightBlue,
                    value: _pinSet,
                    onChanged: (v) async {
                      if (!mounted) return;
                      final confirm = await PanaraConfirmDialog.show<bool>(
                        context,
                        title: v ? 'Enable App Lock?' : 'Disable App Lock?',
                        message: v
                            ? 'Enabling app lock requires creating a PIN and recovery password. Proceed?'
                            : 'Disabling lock will remove the PIN and recovery password. Are you sure?',
                        confirmButtonText: "Confirm",
                        cancelButtonText: "Cancel",
                        onTapCancel: () {
                          Navigator.of(context).pop(false);
                        },
                        onTapConfirm: () {
                          Navigator.of(context).pop(true);
                        },
                        textColor: Colors.grey.shade700,
                        panaraDialogType: v
                            ? PanaraDialogType.success
                            : PanaraDialogType.warning,
                      );

                      if (!mounted) return;
                      if (confirm != true) {
                        if (!mounted) return;
                        await _loadAuthState();
                        return;
                      }

                      if (v) {
                        await _enableAppLock();
                      } else {
                        await _disableAppLock();
                      }
                      if (!mounted) return;
                      await _loadAuthState();
                    },
                  ),
                  if (_pinSet) ...[
                    ListTile(
                      title: const Text('Change PIN'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePin,
                    ),
                    ListTile(
                      title: const Text('Change recovery password'),
                      subtitle: const Text('Set a new recovery password'),
                      onTap: _setRecoveryPassword,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
