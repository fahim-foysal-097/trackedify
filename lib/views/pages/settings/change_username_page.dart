import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:trackedify/database/database_helper.dart';

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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'New Username',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      prefixIcon: Icon(
                        FontAwesomeIcons.pen,
                        color: theme.textTheme.bodySmall?.color,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: kToolbarHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _saveUsername,
                      child: Text(
                        'Save Username',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onPrimary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
