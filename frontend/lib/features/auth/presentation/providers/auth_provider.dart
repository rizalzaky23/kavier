import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../data/models/license_model.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/license_service.dart';

enum LicenseStatus {
  unknown,
  valid,
  expiringSoon,   // ≤ 7 hari
  expired,
  disabled,
  noLicense,
  offlineCached,  // cache masih valid tapi sedang offline
}

class AuthProvider extends ChangeNotifier {
  UserModel?      _user;
  LicenseModel?   _license;
  LicenseStatus   _licenseStatus = LicenseStatus.unknown;
  bool            _isLoading     = false;
  String?         _errorMessage;

  UserModel?    get user          => _user;
  LicenseModel? get license       => _license;
  LicenseStatus get licenseStatus => _licenseStatus;
  bool          get isLoading     => _isLoading;
  String?       get errorMessage  => _errorMessage;
  bool          get isLoggedIn    => _user != null && _licenseStatus == LicenseStatus.valid
                                      || _licenseStatus == LicenseStatus.expiringSoon
                                      || _licenseStatus == LicenseStatus.offlineCached;

  final _dbService      = DatabaseService();
  final _licenseService = LicenseService();

  // ── Auto Login ─────────────────────────────────────────────────────────

  Future<void> tryAutoLogin() async {
    // Cek apakah ada lisensi cache yang masih valid
    final isValid = await _licenseService.isLicenseValidLocally();
    if (!isValid) return;

    final cached = await _licenseService.getCachedLicense();
    if (cached == null) return;

    // Coba ambil user dari SQLite berdasarkan email cache
    if (cached.email != null) {
      final db   = await _dbService.database;
      final rows = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [cached.email],
      );
      if (rows.isNotEmpty) {
        _user    = UserModel.fromJson(rows.first);
        _license = cached;
        _licenseStatus = _resolveLicenseStatus(cached);
        notifyListeners();
      }
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _isLoading    = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final db = await _dbService.database;

      // 1. Verifikasi lisensi ke server cloud
      final license = await _licenseService.verifyLicense(
        email:    email,
        password: password,
      );

      UserModel? localUser;
      
      // Deteksi apakah response ini berasal dari cache (offline)
      final isOfflineFallback = license.code == 'LICENSE_VALID_CACHED' || 
                                license.message.contains('Tidak dapat terhubung') ||
                                license.message.contains('Mode offline');

      // 2. Analisis respons
      if (isOfflineFallback) {
        // --- SEDANG OFFLINE ---
        // Karena offline, password tidak divalidasi oleh cloud. Kita wajib cek di SQLite.
        final rows = await db.query(
          'users',
          where: 'email = ? AND password = ?',
          whereArgs: [email, password],
        );

        if (rows.isEmpty) {
          _errorMessage = 'Mode Offline: Email atau password salah, atau belum pernah login saat online.';
          return false;
        }
        
        localUser = UserModel.fromJson(rows.first);

        if (!license.valid) {
          _errorMessage  = _buildLicenseError(license);
          _license       = license;
          _licenseStatus = _resolveLicenseStatus(license);
          return false;
        }

      } else {
        // --- SEDANG ONLINE ---
        if (!license.valid) {
          _errorMessage  = _buildLicenseError(license);
          _license       = license;
          _licenseStatus = _resolveLicenseStatus(license);
          return false;
        }

        // Online & Valid: Sinkronisasi user ke SQLite lokal
        final rows = await db.query(
          'users',
          where: 'email = ?',
          whereArgs: [email],
        );

        if (rows.isEmpty) {
          // Buat user baru di lokal agar bisa dipakai offline nanti
          final newUser = {
            'name':     license.name ?? 'User',
            'email':    email,
            'password': password,
            'role':     'admin', // Default
          };
          final id = await db.insert('users', newUser);
          localUser = UserModel(
            id:    id,
            name:  newUser['name'] as String,
            email: newUser['email'] as String,
            role:  newUser['role'] as String,
          );
        } else {
          // Update password di lokal jika berubah di cloud
          await db.update('users', {'password': password}, where: 'email = ?', whereArgs: [email]);
          final updated = await db.query('users', where: 'email = ?', whereArgs: [email]);
          localUser = UserModel.fromJson(updated.first);
        }
      }

      // 3. Login berhasil
      _user          = localUser;
      _license       = license;
      _licenseStatus = _resolveLicenseStatus(license);
      return true;

    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _licenseService.clearLicense();
    _user          = null;
    _license       = null;
    _licenseStatus = LicenseStatus.unknown;
    notifyListeners();
  }

  // ── Recheck lisensi (periodik / manual) ───────────────────────────────

  Future<void> recheckLicense() async {
    if (_user == null) return;
    final license = await _licenseService.recheckLicense(_user!.email);
    if (license != null) {
      _license       = license;
      _licenseStatus = _resolveLicenseStatus(license);
      if (!license.valid) {
        // Paksa logout jika tidak valid
        await logout();
      }
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  LicenseStatus _resolveLicenseStatus(LicenseModel license) {
    if (!license.valid) {
      switch (license.code) {
        case 'LICENSE_EXPIRED':   return LicenseStatus.expired;
        case 'ACCOUNT_DISABLED': return LicenseStatus.disabled;
        case 'NO_LICENSE':       return LicenseStatus.noLicense;
        default:                 return LicenseStatus.expired;
      }
    }
    if (license.code == 'LICENSE_VALID_CACHED') return LicenseStatus.offlineCached;
    if (license.daysRemaining != null && license.daysRemaining! <= 7) {
      return LicenseStatus.expiringSoon;
    }
    return LicenseStatus.valid;
  }

  String _buildLicenseError(LicenseModel license) {
    switch (license.code) {
      case 'USER_NOT_FOUND':
        return 'Akun tidak terdaftar di sistem lisensi. Hubungi administrator.';
      case 'INVALID_CREDENTIALS':
        return 'Email atau password tidak sesuai dengan data lisensi.';
      case 'LICENSE_EXPIRED':
        final end = license.licenseEnd ?? '-';
        return 'Lisensi Anda telah berakhir pada $end. Silakan hubungi administrator untuk perpanjangan.';
      case 'ACCOUNT_DISABLED':
        return 'Akun Anda telah dinonaktifkan. Hubungi administrator.';
      case 'NO_LICENSE':
        return 'Belum ada lisensi yang ditetapkan untuk akun ini. Hubungi administrator.';
      default:
        return license.message;
    }
  }

  /// Apakah lisensi akan berakhir dalam 7 hari ke depan
  bool get isExpiringSoon =>
      _licenseStatus == LicenseStatus.expiringSoon;

  int? get daysRemaining => _license?.daysRemaining;
  String? get licenseEnd => _license?.licenseEnd;
}
