import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _db;

  factory DatabaseHelper() {
    return _instance;
  }

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
      version: 2, // Incremented version
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
              tips_shown INTEGER DEFAULT 0
            )
          ''');
        });
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add the new column for existing databases
          await db.execute('''
            ALTER TABLE user_info ADD COLUMN tips_shown INTEGER DEFAULT 0
          ''');
        }
      },
    );
  }

  // Wipe all data
  Future<void> wipeAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('user_info');
  }
}
