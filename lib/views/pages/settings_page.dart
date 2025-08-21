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
    // unfocus text field
    FocusScope.of(context).unfocus();

    final db = await DatabaseHelper().database;
    if (userId != null) {
      await db.update(
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
    if (!mounted) return;

    setState(() {
      currentUsername = _usernameController.text;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username saved!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Settings",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                alignment: Alignment.center,
                child: const Text(
                  "Change Your Username",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "New Username",
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.abc_outlined,
                    size: 28,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
                    "Save",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
