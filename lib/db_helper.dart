import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {

  static final DBHelper instance = DBHelper._internal();

  static Database? _db;

  DBHelper._internal();

  Future<Database> get database async {

    if (_db != null) return _db!;

    _db = await _initDB();

    return _db!;
  }

  Future<Database> _initDB() async {

    String path = join(await getDatabasesPath(), 'trip_app.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// ================= CREATE TABLES =================

  Future _onCreate(Database db, int version) async {

    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        password TEXT,
        mobile TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        name TEXT,
        destination TEXT,
        startDate TEXT,
        endDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER,
        name TEXT,
        mobile TEXT,
        email TEXT,
        payAmount REAL,
        isAdmin INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER,
        description TEXT,
        amount REAL,
        category TEXT,
        members TEXT,
        startLocation TEXT,
        endLocation TEXT,
        travelDate TEXT,
        addedBy INTEGER,
        createdAt TEXT
      )
    ''');

    /// MEMBER LEDGER

    await db.execute('''
      CREATE TABLE member_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER,
        memberId INTEGER,
        type TEXT,
        amount REAL,
        note TEXT,
        createdAt TEXT
      )
    ''');

    await createCategoryTable(db);
  }

  /// ================= MIGRATION =================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {

    if (oldVersion < 2) {
      await db.execute("ALTER TABLE expenses ADD COLUMN addedBy INTEGER");
    }

    if (oldVersion < 3) {
      await db.execute("ALTER TABLE users ADD COLUMN mobile TEXT");
    }

    if (oldVersion < 4) {
      await db.execute("ALTER TABLE users ADD COLUMN address TEXT");
    }

    if (oldVersion < 5) {

      await db.execute('''
      CREATE TABLE IF NOT EXISTS member_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER,
        memberId INTEGER,
        type TEXT,
        amount REAL,
        note TEXT,
        createdAt TEXT
      )
      ''');

    }

  }

  /// ================= CATEGORY TABLE =================

  Future<void> createCategoryTable([Database? dbOverride]) async {

    final db = dbOverride ?? await database;

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER,
        name TEXT
      )
    ''');

  }

  /// ================= DEFAULT CATEGORIES =================

  Future<void> addDefaultCategories(int tripId) async {

    final db = await database;

    List<String> defaultCategories = [
      "Travel",
      "Food",
      "Lunch",
      "Dinner",
      "Breakfast",
      "Accommodation"
    ];

    for (var cat in defaultCategories) {

      await db.insert(
        'categories',
        {
          'tripId': tripId,
          'name': cat
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

    }

  }

  Future<List<Map<String, dynamic>>> getCategories(int tripId) async {

    final db = await database;

    return await db.query(
      'categories',
      where: 'tripId = ?',
      whereArgs: [tripId],
    );

  }

  Future<int> addCategory(int tripId, String name) async {

    final db = await database;

    return await db.insert(
      'categories',
      {
        'tripId': tripId,
        'name': name
      },
    );

  }

  /// ================= GENERIC FUNCTIONS =================

  Future<List<Map<String, dynamic>>> getAll(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {

    final db = await database;

    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

  }

  Future<int> insert(String table, Map<String, dynamic> values) async {

    final db = await database;

    return await db.insert(table, values);

  }

  Future<int> update(
    String table,
    Map<String, dynamic> values,
    String where,
    List<Object?> whereArgs,
  ) async {

    final db = await database;

    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );

  }

  Future<int> delete(
    String table,
    String where,
    List<Object?> whereArgs,
  ) async {

    final db = await database;

    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );

  }

  Future<int> insertUser(Map<String, dynamic> values) async {

    final db = await database;

    return await db.insert('users', values);

  }

  /// ================= RESET ADMIN =================

  Future<void> resetAdmin(int tripId) async {

    final db = await database;

    await db.update(
      'members',
      {'isAdmin': 0},
      where: 'tripId = ?',
      whereArgs: [tripId],
    );

  }

  /// ================= MEMBER LEDGER =================

  Future<List<Map<String, dynamic>>> getMemberTransactions(
      int tripId, int memberId) async {

    final db = await database;

    return await db.query(
      'member_transactions',
      where: 'tripId = ? AND memberId = ?',
      whereArgs: [tripId, memberId],
      orderBy: 'createdAt DESC',
    );

  }

  Future<double> getMemberDeposit(int tripId, int memberId) async {

    final db = await database;

    var data = await db.query(
      'member_transactions',
      where: 'tripId = ? AND memberId = ? AND type = ?',
      whereArgs: [tripId, memberId, 'deposit'],
    );

    double total = 0;

    for (var t in data) {
      total += (t['amount'] as num?)?.toDouble() ?? 0;
    }

    return total;

  }

  Future<double> getMemberWithdraw(int tripId, int memberId) async {

    final db = await database;

    var data = await db.query(
      'member_transactions',
      where: 'tripId = ? AND memberId = ? AND type = ?',
      whereArgs: [tripId, memberId, 'withdraw'],
    );

    double total = 0;

    for (var t in data) {
      total += (t['amount'] as num?)?.toDouble() ?? 0;
    }

    return total;

  }

  Future<double> getMemberBalance(int tripId, int memberId) async {

    double deposit = await getMemberDeposit(tripId, memberId);

    double withdraw = await getMemberWithdraw(tripId, memberId);

    return deposit - withdraw;

  }

}