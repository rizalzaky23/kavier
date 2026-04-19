import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/license_model.dart';

class LicenseService {
  // ── Config ─────────────────────────────────────────────────────────────
  // License Server berjalan di port 8001 — terpisah total dari backend lain
  // Endpoint: http://20.39.192.91:8001/api/license/verify
  //           http://20.39.192.91:8001/api/license/check
  static const String _baseUrl = 'http://20.39.192.91:8001/api/license';

  // SharedPreferences keys
  static const _kValid        = 'license_valid';
  static const _kCode         = 'license_code';
  static const _kMessage      = 'license_message';
  static const _kLicenseEnd   = 'license_end';
  static const _kDaysLeft     = 'license_days_remaining';
  static const _kStoreName    = 'license_store_name';
  static const _kEmail        = 'license_email';
  static const _kCachedAt     = 'license_cached_at';

  // Singleton
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  // ── Public API ─────────────────────────────────────────────────────────

  /// Verifikasi lisensi ke server cloud.
  /// Dipanggil saat login dengan kredensial user.
  Future<LicenseModel> verifyLicense({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/verify'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final license = LicenseModel.fromJson(json);

      // Cache hasil ke SharedPreferences
      await _cacheLicense(license);
      return license;
    } on SocketException {
      // Tidak ada koneksi internet — cek cache
      return _getCachedOrExpired();
    } on HttpException {
      return _getCachedOrExpired();
    } catch (_) {
      return _getCachedOrExpired();
    }
  }

  /// Re-check ringan (hanya email, tanpa password).
  /// Dipakai untuk pengecekan periodik di background.
  Future<LicenseModel?> recheckLicense(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/check'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final license = LicenseModel.fromJson(json);
      await _cacheLicense(license);
      return license;
    } catch (_) {
      return null; // Offline atau error — gunakan cache
    }
  }

  /// Cek apakah lisensi cache masih valid (offline-first).
  Future<bool> isLicenseValidLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final valid      = prefs.getBool(_kValid) ?? false;
    final licenseEnd = prefs.getString(_kLicenseEnd);

    if (!valid || licenseEnd == null) return false;

    try {
      final end = DateTime.parse(licenseEnd);
      // Toleransi 1 hari grace period
      return DateTime.now().isBefore(end.add(const Duration(days: 1)));
    } catch (_) {
      return false;
    }
  }

  /// Ambil data lisensi dari cache lokal.
  Future<LicenseModel?> getCachedLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final valid = prefs.getBool(_kValid);
    if (valid == null) return null;

    return LicenseModel(
      valid:         valid,
      code:          prefs.getString(_kCode) ?? '',
      message:       prefs.getString(_kMessage) ?? '',
      email:         prefs.getString(_kEmail),
      storeName:     prefs.getString(_kStoreName),
      licenseEnd:    prefs.getString(_kLicenseEnd),
      daysRemaining: prefs.getInt(_kDaysLeft),
    );
  }

  /// Ambil tanggal expired dari cache (untuk tampilan UI).
  Future<String?> getCachedLicenseEnd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLicenseEnd);
  }

  /// Hapus semua data lisensi (saat logout).
  Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kValid);
    await prefs.remove(_kCode);
    await prefs.remove(_kMessage);
    await prefs.remove(_kLicenseEnd);
    await prefs.remove(_kDaysLeft);
    await prefs.remove(_kStoreName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kCachedAt);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  Future<void> _cacheLicense(LicenseModel license) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kValid, license.valid);
    await prefs.setString(_kCode, license.code);
    await prefs.setString(_kMessage, license.message);
    if (license.licenseEnd != null) {
      await prefs.setString(_kLicenseEnd, license.licenseEnd!);
    }
    if (license.daysRemaining != null) {
      await prefs.setInt(_kDaysLeft, license.daysRemaining!);
    }
    if (license.storeName != null) {
      await prefs.setString(_kStoreName, license.storeName!);
    }
    if (license.email != null) {
      await prefs.setString(_kEmail, license.email!);
    }
    await prefs.setString(_kCachedAt, DateTime.now().toIso8601String());
  }

  Future<LicenseModel> _getCachedOrExpired() async {
    final prefs      = await SharedPreferences.getInstance();
    final valid      = prefs.getBool(_kValid) ?? false;
    final licenseEnd = prefs.getString(_kLicenseEnd);

    bool stillValid = false;
    if (valid && licenseEnd != null) {
      try {
        final end = DateTime.parse(licenseEnd);
        stillValid = DateTime.now().isBefore(end.add(const Duration(days: 1)));
      } catch (_) {}
    }

    return LicenseModel(
      valid:         stillValid,
      code:          stillValid ? 'LICENSE_VALID_CACHED' : 'LICENSE_EXPIRED',
      message:       stillValid
          ? 'Mode offline — lisensi dari cache masih berlaku.'
          : 'Tidak dapat terhubung ke server lisensi dan lisensi lokal sudah expired.',
      email:         prefs.getString(_kEmail),
      storeName:     prefs.getString(_kStoreName),
      licenseEnd:    licenseEnd,
      daysRemaining: prefs.getInt(_kDaysLeft),
    );
  }
}
