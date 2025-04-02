import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'user_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT,
            email TEXT UNIQUE,
            username TEXT,
            firstName TEXT,
            lastName TEXT,
            password TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    try {
      return await db.insert('users', user);
    } catch (e) {
      // Handle unique constraint violations
      if (e.toString().contains('UNIQUE constraint failed')) {
        return await updateUser(user);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }




  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      'users',
      user,
      where: 'email = ?',
      whereArgs: [user['email']],
    );
  }

  Future<int> deleteUser(String email) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}