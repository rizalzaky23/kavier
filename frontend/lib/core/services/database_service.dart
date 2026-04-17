import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pos_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT,
        created_at TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        image_url TEXT,
        created_at TEXT
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT,
        description TEXT,
        price REAL,
        stock INTEGER,
        min_stock INTEGER,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        invoice_number TEXT UNIQUE,
        subtotal REAL,
        tax REAL,
        discount REAL,
        total REAL,
        paid_amount REAL,
        change_amount REAL,
        payment_method TEXT,
        status TEXT,
        notes TEXT,
        created_at TEXT
      )
    ''');

    // Transaction Details table
    await db.execute('''
      CREATE TABLE transaction_details(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER,
        product_id INTEGER,
        name TEXT,
        price REAL,
        quantity INTEGER,
        subtotal REAL,
        created_at TEXT,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    // SEED INITIAL DATA
    _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Admin user
    await db.insert('users', {
      'name': 'Admin Pos',
      'email': 'admin@pos.com',
      'password': 'password', // in real app encrypt this
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String()
    });

    // Dummy Categories
    int foodCatId = await db.insert('categories', {
      'name': 'Makanan',
      'description': 'Aneka Makanan',
      'created_at': DateTime.now().toIso8601String()
    });

    int drinkCatId = await db.insert('categories', {
      'name': 'Minuman',
      'description': 'Aneka Minuman',
      'created_at': DateTime.now().toIso8601String()
    });

    // Dummy Products
    await db.insert('products', {
      'category_id': foodCatId,
      'name': 'Nasi Goreng Spesial',
      'price': 25000.0,
      'stock': 50,
      'min_stock': 10,
      'created_at': DateTime.now().toIso8601String()
    });

    await db.insert('products', {
      'category_id': drinkCatId,
      'name': 'Es Teh Manis',
      'price': 5000.0,
      'stock': 100,
      'min_stock': 20,
      'created_at': DateTime.now().toIso8601String()
    });
  }
}
