import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'market_v6.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            price REAL,
            description TEXT,
            seller_id INTEGER,
            seller_name TEXT,
            seller_email TEXT,
            image_path TEXT,
            status INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE session(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            current_user_id INTEGER,
            current_user_name TEXT,
            current_user_email TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            product_id INTEGER,
            UNIQUE(user_id, product_id)
          )
        ''');
      },
    );
  }

  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;
    try {
      return await db.insert('users', {
        'name': name,
        'email': email,
        'password': password,
      });
    } catch (e) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (res.isNotEmpty) {
      await db.insert('session', {
        'id': 1,
        'current_user_id': res.first['id'],
        'current_user_name': res.first['name'],
        'current_user_email': res.first['email'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return res.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getCurrentSession() async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'session',
      where: 'id = 1',
    );
    return res.isNotEmpty ? res.first : null;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('session', where: 'id = 1');
  }

  Future<List<Product>> getMyListedItems(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'seller_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<void> toggleFavorite(int userId, int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'favorites',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
    if (res.isNotEmpty) {
      await db.delete(
        'favorites',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );
    } else {
      await db.insert('favorites', {
        'user_id': userId,
        'product_id': productId,
      });
    }
  }

  Future<bool> isFavorite(int userId, int productId) async {
    final db = await database;
    final List<Map<String, dynamic>> res = await db.query(
      'favorites',
      where: 'user_id = ? AND product_id = ?',
      whereArgs: [userId, productId],
    );
    return res.isNotEmpty;
  }

  Future<List<Product>> getMyFavorites(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT p.* FROM products p 
      INNER JOIN favorites f ON p.id = f.product_id 
      WHERE f.user_id = ? ORDER BY f.id DESC
    ''',
      [userId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final session = await getCurrentSession();
    final productData = product.toMap();
    productData['seller_id'] = session?['current_user_id'] ?? 0;
    productData['seller_name'] = session?['current_user_name'] ?? 'Anonymous';
    productData['seller_email'] =
        session?['current_user_email'] ?? 'unknown@xmu.edu.my';
    productData['status'] = 0;
    return await db.insert('products', productData);
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'status = 0',
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> searchProducts(String keyword) async {
    final db = await database;
    final int? searchId = int.tryParse(keyword);
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: '(title LIKE ? OR seller_id = ?) AND status = 0',
      whereArgs: ['%$keyword%', searchId ?? -1],
      orderBy: 'id DESC',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
