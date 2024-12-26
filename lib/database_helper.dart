import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 3, // Yeni sürüm numarası
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await _upgradeToVersion3(db);
        }
      },
    );
  }

  // Tabloları oluşturma
  Future<void> _createTables(Database db) async {
    // Kullanıcılar tablosu
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        company_name TEXT,
        photo BLOB -- Fotoğraf için
      )
    ''');

    // Gelir-Gider tablosu
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT, -- 'income' veya 'expense'
        amount REAL,
        description TEXT,
        date TEXT,
        user_id INTEGER,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');
  }

  // Veritabanını 3. sürüme yükseltme
  Future<void> _upgradeToVersion3(Database db) async {
    // Kullanıcılar tablosuna şirket bilgisi ve fotoğraf ekleme
    await db.execute('''
      ALTER TABLE users ADD COLUMN company_name TEXT
    ''');
    await db.execute('''
      ALTER TABLE users ADD COLUMN photo BLOB
    ''');
  }

  // Kullanıcı bilgilerini al
  Future<Map<String, dynamic>?> getUserDetails(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateUserDetails(Map<String, dynamic> userDetails) async {
    final db = await database;
    await db.update(
      'users',
      {
        'username': userDetails['new_username'],
        'password': userDetails['password'],
        'company_name': userDetails['company_name'],
        'photo': userDetails['photo'],
      },
      where: 'username = ?',
      whereArgs: [userDetails['username']],
    );
  }

  // Kullanıcı ekleme
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Kullanıcıları alma
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // Kullanıcıyı kullanıcı adı ve şifreyle alma
  Future<Map<String, dynamic>?> getUserByUsernameAndPassword(String username, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Kullanıcıyı silme
  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Gelir-Gider Ekleme
  Future<void> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    await db.insert('transactions', transaction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Gelir-Gider Listeleme
  Future<List<Map<String, dynamic>>> getTransactionsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  // Tarih aralığına göre Gelir-Gider Listeleme
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(
      int userId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );
  }

  Future<double> getTotalIncome(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND user_id = ?',
      ['gelir', userId],
    );
    return result[0]['total'] != null ? (result[0]['total'] as num).toDouble() : 0.0;
  }

  Future<double> getTotalExpense(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = ? AND user_id = ?',
      ['gider', userId],
    );
    return result[0]['total'] != null ? (result[0]['total'] as num).toDouble() : 0.0;
  }

  // Giriş Silme
  Future<void> deleteTransaction(int transactionId) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Giriş Güncelleme
  Future<void> updateTransaction(int transactionId, Map<String, dynamic> updatedData) async {
    final db = await database;
    await db.update(
      'transactions',
      updatedData,
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Tüm tabloyu temizleme
  Future<void> clearTable(String tableName) async {
    final db = await database;
    await db.delete(tableName);
  }
}
