import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isProcessing = false;
  int _expenseCount = 0;
  int _categoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void showTipsDialog() {
    const tips =
        '''You can import / restore you data from valid JSON and SQLite database. Importing from DB will replace all data. You can replace / append new data by importing valid JSON.''';

    PanaraInfoDialog.show(
      context,
      title: 'Hints & Tips',
      message: tips,
      buttonText: 'Got it',
      onTapDismiss: () => Navigator.pop(context),
      textColor: Colors.black54,
      panaraDialogType: PanaraDialogType.normal,
    );
  }

  Future<void> _loadSummary() async {
    try {
      final db = await _dbHelper.database;
      final expenses = await db.query('expenses');
      final categories = await db.query('categories');
      if (!mounted) return;
      setState(() {
        _expenseCount = expenses.length;
        _categoryCount = categories.length;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading DB summary: $e');
    }
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

  // Import DB (.db)
  Future<bool> _importDb() async {
    if (_isProcessing || !mounted) return false;
    setState(() => _isProcessing = true);

    bool spinnerShown = false;
    try {
      // let user pick .db file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (!mounted) return false;
      if (result == null || result.files.single.path == null) {
        // user cancelled
        if (kDebugMode) debugPrint('DB import cancelled');
        return false;
      }

      final importPath = result.files.single.path!;
      final importFile = File(importPath);
      if (!await importFile.exists()) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file does not exist.')),
        );
        return false;
      }

      // show spinner while validating and importing
      if (!mounted) return false;
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
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selected file is not a valid Spendle database or is corrupted. Import cancelled.',
            ),
          ),
        );
        return false;
      }

      // calling helper to copy/import DB
      try {
        await _dbHelper.importDatabase(importPath);
      } catch (e) {
        // helper threw - treat as failure
        if (spinnerShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          spinnerShown = false;
        }
        if (!mounted) return false;
        if (kDebugMode) debugPrint('Helper importDatabase threw: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('DB import failed: $e')));
        return false;
      }

      // close any open db handle inside helper
      try {
        await _dbHelper.closeDatabase();
      } catch (e) {
        if (kDebugMode) debugPrint('closeDatabase after import failed: $e');
      }

      // refresh counts
      await _loadSummary();

      if (!mounted) return true;
      // close spinner
      if (spinnerShown && Navigator.canPop(context)) {
        Navigator.pop(context);
        spinnerShown = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database imported successfully.')),
      );
      return true;
    } catch (e) {
      if (spinnerShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        spinnerShown = false;
      }

      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('DB import failed: $e')));
      return false;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// JSON Import with duplicate skip
  Future<void> _importJson() async {
    if (_isProcessing || !mounted) return;

    // Ask whether to Append or Replace
    final action = await showDialog<_JsonImportAction>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Import JSON',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Do you want to append the JSON data to your existing data, '
            'or replace existing tables (expenses, categories, user_info)?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_JsonImportAction.append),
              child: const Text('Append'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_JsonImportAction.replace),
              child: const Text('Replace'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (action == null) return;

    setState(() => _isProcessing = true);
    bool spinnerShown = false;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (!mounted) return;
      if (result == null || result.files.single.path == null) {
        if (kDebugMode) debugPrint('JSON import cancelled by user');
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

      // show spinner
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      spinnerShown = true;

      final raw = await importFile.readAsString();
      final dynamic decoded = json.decode(raw);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid JSON format: expected object root.');
      }

      final db = await _dbHelper.database;

      // When replacing, wipe tables inside a transaction for safety
      if (action == _JsonImportAction.replace) {
        await db.transaction((txn) async {
          await txn.delete('expenses');
          await txn.delete('categories');
          await txn.delete('user_info');
        });
      }

      int insertedExpenses = 0;
      int insertedCategories = 0;
      int insertedUsers = 0;
      int skippedExpenses = 0;
      int skippedCategories = 0;

      // Categories
      if (decoded.containsKey('categories') && decoded['categories'] is List) {
        for (var c in decoded['categories']) {
          if (c is Map<String, dynamic>) {
            final name = c['name']?.toString();
            final colorVal = c['color'];
            final iconVal = c['icon_code'];

            if (name == null) {
              skippedCategories++;
              continue;
            }
            try {
              // using helper that respects conflictAlgorithm.ignore
              await _dbHelper.addCategory(
                name,
                (colorVal is int)
                    ? colorVal
                    : (int.tryParse('$colorVal') ?? 0xFF000000),
                (iconVal is int) ? iconVal : (int.tryParse('$iconVal') ?? 0),
              );
              insertedCategories++;
            } catch (_) {
              skippedCategories++;
            }
          }
        }
      }

      // Expenses (deduplicate)
      if (decoded.containsKey('expenses') && decoded['expenses'] is List) {
        for (var r in decoded['expenses']) {
          if (r is Map<String, dynamic>) {
            try {
              final category = r['category']?.toString() ?? 'Unknown';
              final amount = (r['amount'] is num)
                  ? (r['amount'] as num).toDouble()
                  : double.tryParse('${r['amount']}') ?? 0.0;
              final date =
                  r['date']?.toString() ?? DateTime.now().toIso8601String();
              final note = r['note']?.toString();

              // basic validation
              if (amount.isNaN || amount < 0) {
                skippedExpenses++;
                continue;
              }

              // --- Deduplication check ---
              final existing = await db.query(
                'expenses',
                where:
                    'category = ? AND amount = ? AND date = ? AND (note IS ? OR note = ?)',
                whereArgs: [category, amount, date, null, note],
                limit: 1,
              );
              if (existing.isNotEmpty) {
                skippedExpenses++;
                continue;
              }

              await _dbHelper.insertExpense(
                category: category,
                amount: amount,
                date: date,
                note: note,
              );
              insertedExpenses++;
            } catch (e) {
              if (kDebugMode) debugPrint('Insert expense failed: $e');
              skippedExpenses++;
            }
          } else {
            skippedExpenses++;
          }
        }
      }

      // user_info
      if (decoded.containsKey('user_info') && decoded['user_info'] is List) {
        final users = decoded['user_info'] as List;
        if (users.isNotEmpty && users.first is Map<String, dynamic>) {
          final u = users.first as Map<String, dynamic>;
          final row = <String, Object?>{};
          if (u.containsKey('username')) {
            row['username'] = u['username']?.toString();
          }
          if (u.containsKey('voice_enabled')) {
            row['voice_enabled'] = (u['voice_enabled'] is int)
                ? u['voice_enabled']
                : ((u['voice_enabled'] == true) ? 1 : 0);
          }
          if (u.containsKey('notification_enabled')) {
            row['notification_enabled'] = (u['notification_enabled'] is int)
                ? u['notification_enabled']
                : ((u['notification_enabled'] == true) ? 1 : 0);
          }

          // insert
          try {
            final inserted = await db.insert('user_info', row);
            if (inserted > 0) insertedUsers++;
          } catch (e) {
            if (kDebugMode) debugPrint('Insert user_info failed: $e');
          }
        }
      }

      // done - refresh summary
      await _loadSummary();

      if (!mounted) return;
      if (spinnerShown && Navigator.canPop(context)) {
        Navigator.pop(context);
        spinnerShown = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'JSON import done — expenses: +$insertedExpenses (skipped $skippedExpenses), '
            'categories: +$insertedCategories (skipped $skippedCategories), user_info: $insertedUsers',
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (spinnerShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        spinnerShown = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('JSON import failed: $e')));
      if (kDebugMode) debugPrint('JSON import failed: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Import both (DB first, then JSON)
  Future<void> _importBothSequentially() async {
    final dbImported = await _importDb();
    if (!dbImported) return; // only continue if DB import was successful

    if (!mounted) return;
    final shouldImportJson = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Import JSON?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Do you also want to import a JSON file now? (optional)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    if (shouldImportJson == true) await _importJson();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(
              Icons.upload_file_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Import from Database (.db) or JSON export.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 18,
            child: Text(label[0], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImportControls() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.deepPurpleAccent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Import options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a file to import. You can replace or append when importing JSON.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _importDb,
                    icon: const Icon(Icons.storage, color: Colors.white),
                    label: const Text(
                      'Import DB',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _importJson,
                    icon: const Icon(Icons.code, color: Colors.white),
                    label: const Text(
                      'Import JSON',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _importBothSequentially,
              icon: const Icon(Icons.sync_alt, color: Colors.white),
              label: const Text(
                'Import Both (DB --> JSON)',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isProcessing)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(),
                  ),
                  SizedBox(width: 10),
                  Text('Import in progress...'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.blueAccent),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Notes:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Importing a .db file replaces the app database. Use with caution.\n'
                    '• Importing JSON can either append data (safe) or replace tables (destructive).\n'
                    '• JSON should follow the export format produced by the app.',
                    style: TextStyle(color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import / Restore'),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        actionsPadding: const EdgeInsets.only(right: 6),
        actions: [
          IconButton(
            tooltip: 'Tips',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: showTipsDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.blueAccent,
        onRefresh: _loadSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      'Expenses',
                      '$_expenseCount',
                      Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatTile(
                      'Categories',
                      '$_categoryCount',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImportControls(),
              const SizedBox(height: 20),
              _buildNotesCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

enum _JsonImportAction { append, replace }
