import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Username'),
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
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
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.edit, color: Colors.grey),
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
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
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
                ],
              ),
            ),
    );
  }
}
