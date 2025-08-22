import 'package:flutter/material.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/views/widget_tree.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  final TextEditingController nameController = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveUsername() async {
    final username = nameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    setState(() {
      isSaving = true;
    });

    final db = await DatabaseHelper().database;
    await db.insert('user_info', {'username': username});

    setState(() {
      isSaving = false;
    });

    // Navigate to main app
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WidgetTree()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter your name to get started',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Your Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveUsername,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 18),
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
