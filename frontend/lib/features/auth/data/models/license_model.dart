class LicenseModel {
  final bool valid;
  final String code;
  final String message;
  final String? name;
  final String? storeName;
  final String? email;
  final String? licenseStart;
  final String? licenseEnd;
  final int? daysRemaining;

  const LicenseModel({
    required this.valid,
    required this.code,
    required this.message,
    this.name,
    this.storeName,
    this.email,
    this.licenseStart,
    this.licenseEnd,
    this.daysRemaining,
  });

  factory LicenseModel.fromJson(Map<String, dynamic> json) => LicenseModel(
        valid:         json['valid'] as bool,
        code:          json['code'] as String,
        message:       json['message'] as String,
        name:          json['name'] as String?,
        storeName:     json['store_name'] as String?,
        email:         json['email'] as String?,
        licenseStart:  json['license_start'] as String?,
        licenseEnd:    json['license_end'] as String?,
        daysRemaining: json['days_remaining'] as int?,
      );

  /// Apakah lisensi sudah expired berdasarkan tanggal lokal
  bool get isExpiredLocally {
    if (licenseEnd == null) return true;
    try {
      final end = DateTime.parse(licenseEnd!);
      return DateTime.now().isAfter(end.add(const Duration(days: 1)));
    } catch (_) {
      return true;
    }
  }

  /// Label singkat untuk status
  String get statusLabel {
    if (!valid) {
      switch (code) {
        case 'LICENSE_EXPIRED':   return 'Lisensi Expired';
        case 'ACCOUNT_DISABLED': return 'Akun Dinonaktifkan';
        case 'NO_LICENSE':       return 'Tidak Ada Lisensi';
        default:                 return 'Akses Ditolak';
      }
    }
    if (daysRemaining != null && daysRemaining! <= 7) {
      return 'Aktif — ${daysRemaining} hari tersisa';
    }
    return 'Aktif';
  }
}
