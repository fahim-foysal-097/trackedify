import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/shared/widgets/app_snackbar.dart';
import 'package:trackedify/shared/widgets/custom_button.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final TextEditingController _usernameController = TextEditingController();

  int? userId;
  String currentUsername = "";

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
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
    setState(() => _loading = false);
  }

  Future<void> _saveUsername() async {
    FocusScope.of(context).unfocus();
    final db = await DatabaseHelper().database;
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Username cannot be empty!');
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
    AppSnackBar.showSuccess(
      context,
      'Username saved!',
      icon: Icons.check_circle_outline,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Username'),
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 25,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1C1C1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.3
                                : 0.05,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.manage_accounts_rounded,
                            size: 36,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Personalize',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a name to customize your experience',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _usernameController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your unique name',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            label: 'Save Changes',
                            onPressed: _saveUsername,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
