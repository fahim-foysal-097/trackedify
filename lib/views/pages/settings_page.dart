import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/services/auth_service.dart';
import 'package:spendle/views/pages/set_pin_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _auth = AuthService();

  int? userId;
  String currentUsername = "";

  bool _loadingAuthState = true;
  bool _pinSet = false;

  bool _voiceEnabled = true;
  bool _loadingVoicePref = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAuthState();
    _loadVoicePref();
  }

  Future<void> _loadUser() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('user_info');

    if (!mounted) return;
    if (result.isNotEmpty) {
      setState(() {
        userId = result.first['id'] as int?;
        currentUsername = (result.first['username'] ?? 'Guest') as String;
        _usernameController.text = currentUsername;
      });
    } else {
      final id = await db.insert('user_info', {'username': 'Guest'});
      if (!mounted) return;
      setState(() {
        userId = id;
        currentUsername = 'Guest';
        _usernameController.text = 'Guest';
      });
    }
  }

  Future<void> _loadAuthState() async {
    final pinSet = await _auth.isPinSet();
    if (!mounted) return;
    setState(() {
      _pinSet = pinSet;
      _loadingAuthState = false;
    });
  }

  Future<void> _loadVoicePref() async {
    final v = await DatabaseHelper().isVoiceEnabled();
    if (!mounted) return;
    setState(() {
      _voiceEnabled = v;
      _loadingVoicePref = false;
    });
  }

  Future<void> _saveUsername() async {
    FocusScope.of(context).unfocus();
    final db = await DatabaseHelper().database;
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
      return;
    }
    if (userId != null) {
      await db.update(
        'user_info',
        {'username': newName},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } else {
      userId = await db.insert('user_info', {'username': newName});
    }
    if (!mounted) return;
    setState(() => currentUsername = newName);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Username saved!')));
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
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildSecuritySection() {
    if (_loadingAuthState) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            title: const Text('Set recovery password'),
            subtitle: const Text('Allow reset via recovery password'),
            onTap: _setRecoveryPassword,
          ),
        ],

        const SizedBox(height: 20),

        // --------------------------
        // Voice commands preference
        // --------------------------
        const Text(
          'Voice Commands',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _loadingVoicePref
            ? const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              )
            : SwitchListTile(
                title: const Text('Enable voice commands'),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade400,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.lightBlue,
                subtitle: const Text(
                  'Use voice to add expenses (e.g., "add food 20 or shopping 500")',
                ),
                value: _voiceEnabled,
                onChanged: (v) async {
                  // persist in DB
                  await DatabaseHelper().setVoiceEnabled(v);
                  if (!mounted) return;
                  setState(() => _voiceEnabled = v);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        v
                            ? 'Voice commands enabled'
                            : 'Voice commands disabled',
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Lottie.asset(
                  'assets/lotties/settings.json',
                  height: 160,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Change Your Username',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'New Username',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
                  onPressed: _saveUsername,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _buildSecuritySection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
