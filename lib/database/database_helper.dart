import 'dart:io';
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

  Future<Database> initDb() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, "expense_tracker.db");

    return await openDatabase(
      path,
      version: 2,
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
              date TEXT NOT NULL
            )
          ''');

          // --- Table: User Info ---
          await txn.execute('''
            CREATE TABLE user_info (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              history_tip_shown INTEGER DEFAULT 0,
              add_tip_shown INTEGER DEFAULT 0
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

          await _insertDefaultCategories(txn);
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add columns safely
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
}
