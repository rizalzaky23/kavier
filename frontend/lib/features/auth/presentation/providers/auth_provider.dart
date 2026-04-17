import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../../../core/services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user         => _user;
  bool       get isLoading    => _isLoading;
  String?    get errorMessage => _errorMessage;
  bool       get isLoggedIn   => _user != null;

  final _dbService = DatabaseService();

  Future<void> tryAutoLogin() async {
    // For local offline app, we can skip session token check 
    // or implement SQLite sessions later.
  }

  Future<bool> login(String email, String password) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (maps.isNotEmpty) {
        _user = UserModel.fromJson(maps.first);
        return true;
      } else {
        _errorMessage = 'Email atau password salah.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal mengakses database lokal.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }
}
