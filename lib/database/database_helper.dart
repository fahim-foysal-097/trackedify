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
      version: 1,
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
              username TEXT NOT NULL
            )
          ''');

          // Insert default user row with username
          await db.insert('user_info', {'id': 1, 'username': 'User Name'});
        });
      },
    );
  }

  // Get user info
  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    final res = await db.query('user_info', limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  // Update user info
  Future<void> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'user_info',
      user,
      where: 'id = ?',
      whereArgs: [1], // Assuming single row with id=1
    );
  }

  // Wipe all tables
  Future<void> wipeAllData() async {
    final db = await database;
    await db.delete('expenses');
    // await db.delete('user_info');
  }
}
