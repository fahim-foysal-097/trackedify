import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:trackedify/services/auth_service.dart';
import 'package:trackedify/views/pages/set_pin_page.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  final AuthService _auth = AuthService();

  bool _loading = true;
  bool _pinSet = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final set = await _auth.isPinSet();
    if (!mounted) return;
    setState(() {
      _pinSet = set;
      _loading = false;
    });
  }

  void _showTipsDialog() {
    final theme = Theme.of(context);
    PanaraInfoDialog.show(
      context,
      title: 'Security tips',
      message:
          'Enable App Lock (PIN) to protect your data. You can change PIN, reset it with your recovery password, or set a recovery password below.',
      buttonText: 'Got it',
      textColor: theme.textTheme.bodySmall?.color,
      onTapDismiss: () => Navigator.pop(context),
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  Future<String?> _promptForPinOrRecovery({
    required String title,
    required String hint,
    bool obscure = true,
  }) async {
    if (!mounted) return null;
    final ctl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: TextField(
          controller: ctl,
          obscureText: obscure,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctl.text.trim()),
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _enableAppLock() async {
    if (!_pinSet) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const SetPinPage(isChanging: false)),
      );
      if (!mounted) return;
      if (result == true) {
        await _loadAuthState();
        if (!mounted) return;
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: cs.primary,
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: cs.onPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'App lock enabled',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }
    setState(() => _pinSet = true);
  }

  Future<void> _disableAppLock() async {
    final pin = await _promptForPinOrRecovery(
      title: 'Confirm to disable app lock',
      hint: 'Enter PIN',
    );
    if (!mounted || pin == null || pin.isEmpty) return;
    final ok = await _auth.verifyPin(pin);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
      return;
    }
    await _auth.disablePin();
    await _loadAuthState();
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.error,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: cs.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'App lock disabled',
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePin() async {
    final current = await _promptForPinOrRecovery(
      title: 'Confirm current PIN',
      hint: 'Enter current PIN',
    );
    if (!mounted || current == null || current.isEmpty) return;
    final ok = await _auth.verifyPin(current);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wrong PIN')));
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SetPinPage(isChanging: true)),
    );
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

    final currentPin = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify PIN'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: TextField(
          controller: pinCtl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter current PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, pinCtl.text.trim()),
            child: const Text('Verify', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted || currentPin == null || currentPin.isEmpty) return;

    final isValid = await _auth.verifyPin(currentPin);
    if (!mounted) return;
    if (!isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
      return;
    }

    final recoveryCtl = TextEditingController();
    final newRecovery = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set new recovery password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: TextField(
          controller: recoveryCtl,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter new recovery password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, recoveryCtl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || newRecovery == null || newRecovery.isEmpty) return;
    await _auth.setRecoveryPassword(newRecovery);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recovery password saved')));
  }

  Future<void> _resetPinWithRecovery() async {
    final recovery = await _promptForPinOrRecovery(
      title: 'Reset PIN with recovery password',
      hint: 'Enter recovery password',
      obscure: true,
    );
    if (!mounted || recovery == null || recovery.isEmpty) return;

    final ok = await _auth.verifyRecoveryPassword(recovery);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect recovery password')),
      );
      return;
    }

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SetPinPage(isChanging: false)),
    );

    if (created == true) {
      await _loadAuthState();
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.primary,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: cs.onPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PIN has been reset',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _onToggleLock(bool v) async {
    final theme = Theme.of(context);
    final confirm = await PanaraConfirmDialog.show<bool>(
      context,
      title: v ? 'Enable App Lock?' : 'Disable App Lock?',
      message: v
          ? 'Enabling requires creating a PIN and recovery password. Proceed?'
          : 'Disabling lock will remove the PIN and recovery password. Are you sure?',
      confirmButtonText: "Confirm",
      cancelButtonText: "Cancel",
      textColor: theme.textTheme.bodySmall?.color,
      onTapCancel: () => Navigator.pop(context, false),
      onTapConfirm: () => Navigator.pop(context, true),
      panaraDialogType: v ? PanaraDialogType.success : PanaraDialogType.warning,
    );

    if (confirm != true) {
      await _loadAuthState();
      return;
    }

    setState(() => _processing = true);
    if (v) {
      await _enableAppLock();
    } else {
      await _disableAppLock();
    }
    if (!mounted) return;
    setState(() => _processing = false);
    await _loadAuthState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        leading: IconButton(
          tooltip: "Back",
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline, color: cs.onSurface),
            onPressed: _showTipsDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  Text(
                    'Security',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    color: cs.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          'Enable App Lock (PIN)',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Protect the app with a 4+ digit PIN',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: _processing
                            ? const SizedBox(
                                width: 46,
                                height: 30,
                                child: Center(
                                  child: CupertinoActivityIndicator(),
                                ),
                              )
                            : CupertinoSwitch(
                                activeTrackColor: Colors.deepPurple,
                                value: _pinSet,
                                onChanged: (v) async => await _onToggleLock(v),
                              ),
                        onTap: () async => await _onToggleLock(!_pinSet),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pinSet)
                    Card(
                      color: cs.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Change PIN'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _changePin,
                          ),
                          // const Divider(height: 1),
                          ListTile(
                            title: const Text('Change recovery password'),
                            subtitle: const Text(
                              'Create or replace recovery password',
                            ),
                            onTap: _setRecoveryPassword,
                          ),
                          // const Divider(height: 1),
                          ListTile(
                            title: const Text(
                              'Reset PIN (use recovery password)',
                            ),
                            subtitle: const Text(
                              'If you forgot PIN, verify recovery password and create a new PIN',
                            ),
                            trailing: const Icon(Icons.refresh),
                            onTap: _resetPinWithRecovery,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
