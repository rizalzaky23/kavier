import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../../../core/services/database_service.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel>  _products   = [];
  List<CategoryModel> _categories = [];
  List<ProductModel>  _lowStock   = [];
  bool    _isLoading    = false;
  String? _errorMessage;
  String  _searchQuery  = '';
  int?    _selectedCategoryId;

  List<ProductModel>  get products   => _products;
  List<CategoryModel> get categories => _categories;
  List<ProductModel>  get lowStock   => _lowStock;
  bool    get isLoading    => _isLoading;
  String? get errorMessage => _errorMessage;

  final _dbService = DatabaseService();

  Future<void> loadAll() async {
    await Future.wait([fetchProducts(), fetchCategories(), fetchLowStock()]);
  }

  Future<void> fetchProducts({String? search, int? categoryId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _dbService.database;
      String query = 'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id';
      List<dynamic> args = [];
      List<String> conditions = [];

      if (search != null && search.isNotEmpty) {
        conditions.add('p.name LIKE ?');
        args.add('%$search%');
      }
      if (categoryId != null) {
        conditions.add('p.category_id = ?');
        args.add(categoryId);
      }

      if (conditions.isNotEmpty) {
        query += ' WHERE ' + conditions.join(' AND ');
      }
      query += ' ORDER BY p.id DESC';

      final maps = await db.rawQuery(query, args);

      _products = maps.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (map['category_id'] != null) {
          map['category'] = {'id': map['category_id'], 'name': map['category_name']};
        }
        map['low_stock_threshold'] = map['min_stock'];
        map['is_active'] = map['is_active'] == 1;
        map['is_low_stock'] = (map['stock'] as int) <= (map['min_stock'] as int);
        return ProductModel.fromJson(map);
      }).toList();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query('categories');
      _categories = maps.map((e) => CategoryModel.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchLowStock() async {
    try {
      final db = await _dbService.database;
      final maps = await db.rawQuery('''
        SELECT p.*, c.name as category_name 
        FROM products p 
        LEFT JOIN categories c ON p.category_id = c.id 
        WHERE p.stock <= p.min_stock
      ''');
      _lowStock = maps.map((e) {
        final map = Map<String, dynamic>.from(e);
        if (map['category_id'] != null) {
          map['category'] = {'id': map['category_id'], 'name': map['category_name']};
        }
        map['low_stock_threshold'] = map['min_stock'];
        map['is_active'] = map['is_active'] == 1;
        map['is_low_stock'] = true;
        return ProductModel.fromJson(map);
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final db = await _dbService.database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    final db = await _dbService.database;
    await db.insert('products', {
      'name': data['name'],
      'category_id': data['category_id'],
      'price': double.parse(data['price'].toString()),
      'stock': int.parse(data['stock'].toString()),
      'min_stock': 5,
      'description': data['description'],
      'image_url': data['image_url'],
      'created_at': DateTime.now().toIso8601String()
    });
    await loadAll();
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final db = await _dbService.database;
    await db.update('products', {
      'name': data['name'],
      'category_id': data['category_id'],
      'price': double.parse(data['price'].toString()),
      'stock': int.parse(data['stock'].toString()),
      'description': data['description'],
      'image_url': data['image_url'],
    }, where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }
}
