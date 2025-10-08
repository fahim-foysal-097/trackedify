import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 6,
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
              notification_enabled INTEGER DEFAULT 1,
              notification_hour INTEGER DEFAULT 20,
              notification_minute INTEGER DEFAULT 0
            )
          ''');

          // --- Table: Image Notes (stores raw image binary as BLOB) ---
          await txn.execute('''
            CREATE TABLE img_notes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              expense_id INTEGER,
              image BLOB NOT NULL,
              caption TEXT,
              created_at TEXT DEFAULT (datetime('now')),
              FOREIGN KEY(expense_id) REFERENCES expenses(id) ON DELETE CASCADE
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

        if (oldVersion < 5) {
          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN notification_hour INTEGER DEFAULT 20',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE user_info ADD COLUMN notification_minute INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }

        if (oldVersion < 6) {
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS img_notes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                expense_id INTEGER,
                image BLOB NOT NULL,
                caption TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY(expense_id) REFERENCES expenses(id) ON DELETE CASCADE
              )
            ''');
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
    await db.delete('img_notes');
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

  // -------------------------
  // Notification time helpers
  // -------------------------

  /// Returns a map with keys 'hour' and 'minute'. Defaults to 20:00 if not set.
  Future<Map<String, int>> getNotificationTime() async {
    final db = await database;
    final rows = await db.query('user_info', limit: 1);
    if (rows.isEmpty) {
      // default 20:00
      return {'hour': 20, 'minute': 0};
    }
    final first = rows.first;
    final hour = (first['notification_hour'] is int)
        ? first['notification_hour'] as int
        : (first['notification_hour'] != null)
        ? int.tryParse(first['notification_hour'].toString()) ?? 20
        : 20;
    final minute = (first['notification_minute'] is int)
        ? first['notification_minute'] as int
        : (first['notification_minute'] != null)
        ? int.tryParse(first['notification_minute'].toString()) ?? 0
        : 0;
    return {'hour': hour, 'minute': minute};
  }

  /// Set the notification time for the single user row. Inserts a user row if none exists.
  Future<void> setNotificationTime(int hour, int minute) async {
    final db = await database;
    final rows = await db.query('user_info', limit: 1);
    if (rows.isEmpty) {
      await db.insert('user_info', {
        'username': 'User',
        'notification_enabled': 1,
        'notification_hour': hour,
        'notification_minute': minute,
      });
      return;
    }
    final id = rows.first['id'] as int;
    await db.update(
      'user_info',
      {'notification_hour': hour, 'notification_minute': minute},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -------------------------
  // Image notes (img_notes) - store raw bytes (BLOB)
  // -------------------------

  /// Insert an image note. 'expenseId' optional; if provided, image ties to that expense.
  /// 'image' must be a Uint8List (File.readAsBytes() to get it).
  Future<int> insertImageNote({
    int? expenseId,
    required Uint8List image,
    String? caption,
  }) async {
    final db = await database;
    return db.insert('img_notes', {
      'expense_id': expenseId,
      'image': image,
      'caption': caption,
    });
  }

  /// Get all image notes (optionally filter by expenseId)
  Future<List<Map<String, dynamic>>> getImageNotes({int? expenseId}) async {
    final db = await database;
    if (expenseId != null) {
      return db.query(
        'img_notes',
        where: 'expense_id = ?',
        whereArgs: [expenseId],
        orderBy: 'id DESC',
      );
    } else {
      return db.query('img_notes', orderBy: 'id DESC');
    }
  }

  /// Get a single image note by id.
  Future<Map<String, dynamic>?> getImageNoteById(int id) async {
    final db = await database;
    final rows = await db.query('img_notes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Update image note (caption and/or image)
  Future<int> updateImageNote({
    required int id,
    Uint8List? image,
    String? caption,
  }) async {
    final db = await database;
    final Map<String, Object?> values = {};
    if (image != null) values['image'] = image;
    if (caption != null) values['caption'] = caption;
    if (values.isEmpty) return 0;
    return db.update('img_notes', values, where: 'id = ?', whereArgs: [id]);
  }

  /// Delete an image note
  Future<int> deleteImageNote(int id) async {
    final db = await database;
    return db.delete('img_notes', where: 'id = ?', whereArgs: [id]);
  }
}
