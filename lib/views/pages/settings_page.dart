import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();
  int? userId;
  String currentUsername = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final db = await DatabaseHelper().database;
    final result = await db.query('user_info');

    if (result.isNotEmpty) {
      setState(() {
        userId = result.first['id'] as int;
        currentUsername = result.first['username'] as String;
        _usernameController.text = currentUsername;
      });
    } else {
      // insert default
      userId = await db.insert('user_info', {'username': 'Guest'});
      setState(() {
        currentUsername = 'Guest';
        _usernameController.text = 'Guest';
      });
    }
  }

  Future<void> _saveUsername() async {
    final db = await DatabaseHelper().database;
    if (userId != null) {
      db.update(
        'user_info',
        {'username': _usernameController.text},
        where: 'id = ?',
        whereArgs: [userId],
      );
    } else {
      userId = await db.insert('user_info', {
        'username': _usernameController.text,
      });
    }

    setState(() {
      currentUsername = _usernameController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Username: $currentUsername",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Change Username",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveUsername, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}
