import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:trackedify/database/database_helper.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isExporting = false;
  bool _isProcessingDb = false;
  int _expenseCount = 0;
  int _categoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void showTipsDialog() {
    const tips =
        '''You can export / backup your data in CSV, JSON and SQLite database format. If you only want to keep backup of your data, export DB/JSON. You can only backup image notes by exporting DB.''';

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

  Future<Directory> _getExportDir() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, 'exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _loadSummary() async {
    final db = await _dbHelper.database;
    final expenses = await db.query('expenses');
    final categories = await db.query('categories');

    if (mounted) {
      setState(() {
        _expenseCount = expenses.length;
        _categoryCount = categories.length;
      });
    }
  }

  String timestamp() {
    final now = DateTime.now();
    final timestamp =
        '${now.year.toString()}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}-T-'
        '${now.hour.toString().padLeft(2, '0')}-'
        '${now.minute.toString().padLeft(2, '0')}';
    return timestamp;
  }

  String _safeCsvCell(Object? o) {
    final s = o == null ? '' : o.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      final escaped = s.replaceAll('"', '""');
      return '"$escaped"';
    }
    return s;
  }

  Future<File> _writeStringToFileInAppExports(
    String filename,
    String content,
  ) async {
    final dir = await _getExportDir();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content, flush: true);
    return file;
  }

  /// Create a temporary file (in cache) and return its File object
  Future<File> _createTempFile(String fileName, String content) async {
    final tmpDir = await getTemporaryDirectory();
    final tmpFile = File(p.join(tmpDir.path, fileName));
    await tmpFile.writeAsString(content, flush: true);
    return tmpFile;
  }

  /// Save a source file via platform save dialog (SAF on Android 11+).
  /// If dialog not available or user cancels, falls back to copying to app exports folder.
  Future<String?> _saveFileWithDialogAndFallback(
    File sourceFile,
    String defaultFileName,
  ) async {
    // Show platform save dialog using flutter_file_dialog
    try {
      final params = SaveFileDialogParams(
        sourceFilePath: sourceFile.path,
        fileName: defaultFileName,
      );
      final savedPath = await FlutterFileDialog.saveFile(params: params);
      if (savedPath == null) {
        // User cancelled. Return null to caller.
        return null;
      }
      return savedPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Save dialog failed: $e - falling back to app exports folder',
        );
      }
      // Fallback: copy to app exports folder
      final fallbackFile = await _writeStringToFileInAppExports(
        defaultFileName,
        await sourceFile.readAsString(),
      );
      return fallbackFile.path;
    }
  }

  Future<void> _exportDb() async {
    if (_isProcessingDb || !mounted) return;
    setState(() => _isProcessingDb = true);

    bool dialogShown = false;
    try {
      // show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      dialogShown = true;

      // get source DB path via public helper
      final dbPath = await DatabaseHelper().getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        // close spinner if shown
        if (dialogShown && mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          dialogShown = false;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Database file not found.")),
        );
        return;
      }

      final defaultFileName = 'expense_bak_${timestamp()}.db';

      final savedPath = await _saveFileWithDialogAndFallback(
        dbFile,
        defaultFileName,
      );

      // close spinner
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (!mounted) return;

      if (savedPath == null) {
        if (kDebugMode) debugPrint('Export cancelled.');
      } else {
        final bool isContentUri = savedPath.startsWith('content://');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isContentUri
                        ? 'Database exported successfully (SAF URI).'
                        : 'Database exported to: $savedPath',
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // ensure dialog is closed on error
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    } finally {
      if (mounted) setState(() => _isProcessingDb = false);
    }
  }

  /// Export CSV: single CSV file containing only expenses with columns:
  /// id, date, category, amount, note (in that order). Excludes user_info and img_notes.
  Future<void> _exportCsvToSaveDialog() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    bool dialogShown = false;
    File? tmpFile;

    try {
      // Prevent exporting if there are no expenses
      if (_expenseCount == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No expenses to export.')));
        return;
      }

      // show spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      dialogShown = true;

      final db = await _dbHelper.database;

      // Query expenses ordered by date ascending (you can change ordering if needed)
      final expenses = await db.query('expenses', orderBy: 'date ASC');

      // Build CSV - NOTE: strict header + order requested by user
      final sb = StringBuffer();
      // header: id(expense) , daate,category, amount, note
      // we'll use 'date' spelling in header to be correct
      sb.writeln('id,date,category,amount,note');

      for (var row in expenses) {
        // Ensure the exact order: id, date, category, amount, note
        final id = row['id'];
        final date = row['date'];
        final category = row['category'];
        final amount = row['amount'];
        final note = row['note'];

        sb.writeln(
          [
            _safeCsvCell(id),
            _safeCsvCell(date),
            _safeCsvCell(category),
            _safeCsvCell(amount),
            _safeCsvCell(note),
          ].join(','),
        );
      }

      final fileName = 'export_csv_${timestamp()}.csv';
      tmpFile = await _createTempFile(fileName, sb.toString());

      final savedPath = await _saveFileWithDialogAndFallback(tmpFile, fileName);

      // delete tmp
      try {
        if (tmpFile.existsSync()) await tmpFile.delete();
      } catch (_) {}

      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (!mounted) return;

      if (savedPath == null) {
        if (kDebugMode) debugPrint('CSV export cancelled');
      } else {
        final bool isContentUri = savedPath.startsWith('content://');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isContentUri
                        ? 'CSV exported successfully (SAF URI).'
                        : 'CSV exported to: ${p.basename(savedPath)}',
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        if (kDebugMode) {
          debugPrint("CSV export saved: $savedPath");
        }
      }
    } catch (e) {
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Export JSON: create temp JSON file and allow user to choose destination
  Future<void> _exportJsonToSaveDialog() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    bool dialogShown = false;
    File? tmp;

    try {
      // Prevent exporting if there are no expenses
      if (_expenseCount == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No expenses to export.')));
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CupertinoActivityIndicator()),
      );
      dialogShown = true;

      final db = await _dbHelper.database;
      final expenses = await db.query('expenses', orderBy: 'date ASC');
      final categories = await db.query('categories', orderBy: 'id ASC');
      final users = await db.query('user_info');

      final payload = {
        'exported_at': DateTime.now().toIso8601String(),
        'expenses': expenses,
        'categories': categories,
        'user_info': users,
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
      tmp = await _createTempFile('export_json_${timestamp()}.json', jsonStr);

      final saved = await _saveFileWithDialogAndFallback(
        tmp,
        p.basename(tmp.path),
      );
      try {
        if (tmp.existsSync()) await tmp.delete();
      } catch (_) {}

      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (!mounted) return;

      if (saved == null) {
        if (kDebugMode) debugPrint('JSON export cancelled');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.deepPurple,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('JSON export saved: ${p.basename(saved)}'),
                ),
              ],
            ),
          ),
        );
        if (kDebugMode) {
          debugPrint("JSON export saved: ${p.basename(saved)}");
        }
      }
    } catch (e) {
      if (dialogShown && mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
        dialogShown = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('JSON export failed: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportBothToSaveDialog() async {
    if (_expenseCount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No expenses to export.')));
      return;
    }
    await _exportCsvToSaveDialog();
    await _exportJsonToSaveDialog();
    await _exportDb();
  }

  Widget _buildHeader() {
    final bool disableAllExports =
        _expenseCount == 0 || _isExporting || _isProcessingDb;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A90E2), Color(0xFF6C5CE7)],
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
              Icons.download_rounded,
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
                  'Export data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3),
                Text('CSV/JSON/DB', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: disableAllExports ? Colors.grey : Colors.white,
              foregroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: disableAllExports ? null : _exportBothToSaveDialog,
            icon: _isExporting
                ? const SizedBox.shrink()
                : Icon(
                    Icons.file_download,
                    color: disableAllExports ? Colors.white70 : Colors.black87,
                  ),
            label: Text(
              _isExporting ? 'Exporting...' : 'Export All',
              style: TextStyle(
                color: disableAllExports ? Colors.white70 : Colors.black87,
              ),
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

  @override
  Widget build(BuildContext context) {
    final bool disableExports =
        _expenseCount == 0 || _isExporting || _isProcessingDb;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export / Backup'),
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
        onRefresh: () async {
          await _loadSummary();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

              // Quick stats row
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

              // Export controls card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Export options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Choose a format to export.'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: disableExports
                                  ? null
                                  : _exportCsvToSaveDialog,
                              icon: Icon(
                                Icons.table_chart_outlined,
                                color: disableExports
                                    ? Colors.black45
                                    : Colors.white,
                              ),
                              label: Text(
                                'Export CSV',
                                style: TextStyle(
                                  color: disableExports
                                      ? Colors.black45
                                      : Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: disableExports
                                    ? Colors.grey
                                    : Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: disableExports
                                  ? null
                                  : _exportJsonToSaveDialog,
                              icon: Icon(
                                Icons.code,
                                color: disableExports
                                    ? Colors.black45
                                    : Colors.white,
                              ),
                              label: Text(
                                'Export JSON',
                                style: TextStyle(
                                  color: disableExports
                                      ? Colors.black45
                                      : Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: disableExports
                                    ? Colors.grey
                                    : Colors.teal,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                        onPressed: (disableExports) ? null : _exportDb,
                        icon: Icon(
                          Icons.storage,
                          color: disableExports ? Colors.black45 : Colors.white,
                        ),
                        label: Text(
                          _isProcessingDb
                              ? 'Exporting DB...'
                              : 'Export Database (.db)',
                          style: TextStyle(
                            color: disableExports
                                ? Colors.black45
                                : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: disableExports
                              ? Colors.grey
                              : Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: (disableExports)
                            ? null
                            : _exportBothToSaveDialog,
                        icon: Icon(
                          Icons.archive_outlined,
                          color: disableExports ? Colors.black45 : Colors.white,
                        ),
                        label: Text(
                          'Export Both (CSV + JSON)',
                          style: TextStyle(
                            color: disableExports
                                ? Colors.black45
                                : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: disableExports
                              ? Colors.grey
                              : Colors.deepPurpleAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_expenseCount == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No expenses found - add at least one expense to enable exporting.',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (_isExporting || _isProcessingDb)
                        const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CupertinoActivityIndicator(),
                            ),
                            SizedBox(width: 10),
                            Text('Export in progress...'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
