import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sqflite/sqflite.dart';
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

  /// Quick header-based check whether file looks like SQLite.
  bool _looksLikeSqlite(File f) {
    try {
      final raf = f.openSync(mode: FileMode.read);
      final header = raf.readSync(16);
      raf.closeSync();
      final headerStr = String.fromCharCodes(header);
      return headerStr.startsWith('SQLite format 3');
    } catch (e) {
      if (kDebugMode) debugPrint('SQLite header check failed: $e');
      return false;
    }
  }

  /// More thorough validation: try to open DB read-only and ensure at least
  /// one of the expected tables exists.
  Future<bool> _validateDbFile(String path) async {
    final importFile = File(path);
    if (!await importFile.exists()) return false;

    // Fast header check first
    if (!_looksLikeSqlite(importFile)) {
      if (kDebugMode) debugPrint('File does not have SQLite header');
      return false;
    }

    // Attempt to open read-only and check for required tables
    Database? tmpDb;
    try {
      tmpDb = await openDatabase(path, readOnly: true);
      final rows = await tmpDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('expenses','categories','user_info')",
      );
      await tmpDb.close();
      return rows.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('DB validation failed opening file: $e');
      try {
        if (tmpDb != null) await tmpDb.close();
      } catch (_) {}
      return false;
    }
  }

  // Import DB - user picks file
  Future<void> importDb() async {
    if (isImporting || !mounted) return;

    setState(() {
      isImporting = true;
    });

    bool spinnerShown = false;
    try {
      // let user pick .db file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (!mounted) return;

      if (result == null || result.files.single.path == null) {
        // user cancelled
        if (kDebugMode) debugPrint('DB import cancelled');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Import cancelled.")));
        return;
      }

      final importPath = result.files.single.path!;
      final importFile = File(importPath);
      if (!await importFile.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file does not exist.')),
        );
        return;
      }

      // show spinner while validating and importing
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      spinnerShown = true;

      // Validate the file first (header + schema check)
      final isValid = await _validateDbFile(importPath);
      if (!isValid) {
        if (spinnerShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          spinnerShown = false;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected file is not a valid Spendle database or is corrupted. Import cancelled.',
            ),
          ),
        );
        return;
      }

      // calling helper to copy/import DB
      try {
        await DatabaseHelper().importDatabase(importPath);
      } catch (e) {
        // helper threw - treat as failure
        if (spinnerShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          spinnerShown = false;
        }
        if (!mounted) return;
        if (kDebugMode) debugPrint('Helper importDatabase threw: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('DB import failed: $e')));
        return;
      }

      // close any open db handle inside helper
      try {
        await DatabaseHelper().closeDatabase();
      } catch (e) {
        if (kDebugMode) debugPrint('closeDatabase after import failed: $e');
      }

      // close spinner
      if (spinnerShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        spinnerShown = false;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.deepPurple,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Database imported successfully')),
            ],
          ),
        ),
      );

      // Navigate to main app **after successful import**
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const WidgetTree()));
    } catch (e) {
      if (spinnerShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        spinnerShown = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Import failed: $e")));
      }
      if (kDebugMode) debugPrint('Import failed: $e');
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
