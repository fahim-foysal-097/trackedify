import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/views/widget_tree.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> {
  final TextEditingController nameController = TextEditingController();
  String username = "User";
  String? profilePicPath;
  bool showTip = false;
  int? userId;
  bool isSaving = false;
  bool isImporting = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveUsername() async {
    final enteredName = nameController.text.trim();
    if (enteredName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    setState(() {
      isSaving = true;
    });

    final db = await DatabaseHelper().database;
    await db.insert('user_info', {'username': enteredName});

    setState(() {
      isSaving = false;
    });

    // Navigate to main app
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WidgetTree()));
  }

  // Import DB - user picks file
  Future<void> importDb() async {
    setState(() {
      isImporting = true;
    });

    bool dialogShown = false;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (!mounted) return;

      if (result == null || result.files.single.path == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Import cancelled.")));
        return;
      }

      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      dialogShown = true;

      final importPath = result.files.single.path!;
      final importFile = File(importPath);

      if (!await importFile.exists()) {
        if (dialogShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          dialogShown = false;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selected file does not exist.")),
        );
        return;
      }

      // Perform the import
      await DatabaseHelper().importDatabase(importPath);
      await DatabaseHelper().closeDatabase();

      if (!mounted) return;

      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Database imported successfully!")),
      // );
      if (kDebugMode) {
        debugPrint("Database imported successfullt!");
      }

      // Navigate to main app **after successful import**
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const WidgetTree()));
    } catch (e) {
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Import failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/lotties/finance.json', height: 360),
                    const Text(
                      "Almost there",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Your Name",
                        filled: true,
                        fillColor: Colors.white,
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
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSaving ? null : saveUsername,
                        child: isSaving
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Get Started",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: kToolbarHeight,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isImporting ? null : importDb,
                        child: isImporting
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Import Data From DB",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
