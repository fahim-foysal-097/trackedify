import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// TODO : figure out how to store images as notes
// ? maybe use a seperate table

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _db;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<String> _dbPath() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    return join(documentsDir.path, "expense_tracker.db");
  }

  Future<Database> initDb() async {
    String path = await _dbPath();

    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.transaction((txn) async {
          // --- Table: Expenses ---
          await txn.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT NOT NULL,
              amount REAL NOT NULL,
              date TEXT NOT NULL,
              note TEXT
            )
          ''');

          // --- Table: Categories ---
          await txn.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              color INTEGER NOT NULL,
              icon_code INTEGER NOT NULL
            )
          ''');

          // --- Table: User Info ---
          await txn.execute('''
            CREATE TABLE user_info (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              history_tip_shown INTEGER DEFAULT 0,
              add_tip_shown INTEGER DEFAULT 0,
              user_tip_shown INTEGER DEFAULT 0,
              profile_pic TEXT,
              voice_enabled INTEGER DEFAULT 1,
              notification_enabled INTEGER DEFAULT 1
            )
          ''');

          await _insertDefaultCategories(txn);
        });
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN history_tip_shown INTEGER DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN add_tip_shown INTEGER DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN user_tip_shown INTEGER DEFAULT 0',
            );
          } catch (_) {}

          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN profile_pic TEXT',
            );
          } catch (_) {}

          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              color INTEGER NOT NULL,
              icon_code INTEGER NOT NULL
            )
          ''');

          await _insertDefaultCategories(db);
        }

        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE expenses ADD COLUMN note TEXT');
          } catch (_) {}
        }

        if (oldVersion < 4) {
          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN voice_enabled INTEGER DEFAULT 1',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN notification_enabled INTEGER DEFAULT 1',
            );
          } catch (_) {}
        }
      },
    );
  }

  static Future<void> _insertDefaultCategories(DatabaseExecutor db) async {
    final defaultCategories = [
      ['Food', 0xFFFFA500, 0xf736],
      ['Transport', 0xFF2196F3, 0xe1d5],
      ['Shopping', 0xFF673AB7, 0xf37f],
      ['Entertainment', 0xFF4CAF50, 0xf1f5],
      ['Game', 0xFFE91E63, 0xe6aa],
      ['Bills', 0xFFFFC107, 0xe37c],
      ['Health', 0xFFF44336, 0xe305],
      ['Education', 0xFF009688, 0xf33c],
      ['Groceries', 0xFFA52A2A, 0xe395],
      ['Travel', 0xFF00BCD4, 0xe299],
      ['Fuel', 0xFFFF5722, 0xe394],
      ['Subscriptions', 0xFF3F51B5, 0xe618],
      ['Pets', 0xFFCDDC39, 0xe4a1],
      ['Rent', 0xFF607D8B, 0xf107],
      ['Investment', 0xFF673AB7, 0xe67f],
    ];

    for (var cat in defaultCategories) {
      await db.insert(
        'categories',
        {'name': cat[0], 'color': cat[1], 'icon_code': cat[2]},
        conflictAlgorithm: ConflictAlgorithm.ignore, // prevents duplicates
      );
    }
  }

  Future<void> wipeAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('user_info');
    await db.delete('categories');
    await db.execute('VACUUM'); // resets IDs
    await _insertDefaultCategories(db); // repopulate category
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'id ASC');
  }

  Future<int> addCategory(String name, int color, int iconCode) async {
    final db = await database;
    return db.insert('categories', {
      'name': name,
      'color': color,
      'icon_code': iconCode,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // Export DB
  Future<File> exportDatabase(String targetDir) async {
    final dbPath = await _dbPath();
    final dbFile = File(dbPath);

    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true); // create folder if missing
    }

    final fileName = "expense_backup_${DateTime.now()}.db";
    final targetFile = File(join(targetDir, fileName));

    return dbFile.copy(targetFile.path);
  }

  // Import DB from file
  Future<void> importDatabase(String sourcePath) async {
    final dbPath = await _dbPath();

    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    final sourceFile = File(sourcePath);
    await sourceFile.copy(dbPath);

    await database; // reopen
  }

  Future<String> getDatabasePath() async => await _dbPath();

  // -------------------------
  // Helper methods for voice & expenses & notifications
  // -------------------------

  /// Return whether voice commands are enabled (true by default)
  Future<bool> isVoiceEnabled() async {
    final db = await database;
    final rows = await db.query('user_info', limit: 1);
    if (rows.isEmpty) return true;
    final val = rows.first['voice_enabled'];
    if (val == null) return true;
    return (val as int) == 1;
  }

  /// Update voice preference for the first user row.
  Future<void> setVoiceEnabled(bool enabled) async {
    final db = await database;
    final rows = await db.query('user_info', limit: 1);
    if (rows.isEmpty) {
      await db.insert('user_info', {
        'username': 'User',
        'voice_enabled': enabled ? 1 : 0,
      });
      return;
    }
    final id = rows.first['id'] as int;
    await db.update(
      'user_info',
      {'voice_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Return whether notifications are enabled (true by default)
  Future<bool> isNotificationEnabled() async {
    final db = await database;
    final rows = await db.query('user_info', limit: 1);
    if (rows.isEmpty) return true;
    final val = rows.first['notification_enabled'];
    if (val == null) return true;
    return (val as int) == 1;
  }

  /// Update notification preference for the first user row.
  Future<void> setNotificationEnabled(bool enabled) async {
    final db = await database;
    final rows = await db.query('user_info', limit: 1);
    if (rows.isEmpty) {
      await db.insert('user_info', {
        'username': 'User',
        'notification_enabled': enabled ? 1 : 0,
      });
      return;
    }
    final id = rows.first['id'] as int;
    await db.update(
      'user_info',
      {'notification_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Insert an expense.
  Future<int> insertExpense({
    required String category,
    required double amount,
    required String date,
    String? note,
  }) async {
    final db = await database;
    return db.insert('expenses', {
      'category': category,
      'amount': amount,
      'date': date,
      'note': note,
    });
  }
}
