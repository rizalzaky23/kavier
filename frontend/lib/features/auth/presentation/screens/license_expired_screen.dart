import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LicenseExpiredScreen extends StatefulWidget {
  final String? licenseEnd;
  final String? errorCode;

  const LicenseExpiredScreen({
    super.key,
    this.licenseEnd,
    this.errorCode,
  });

  @override
  State<LicenseExpiredScreen> createState() => _LicenseExpiredScreenState();
}

class _LicenseExpiredScreenState extends State<LicenseExpiredScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.errorCode) {
      case 'ACCOUNT_DISABLED': return 'Akun Dinonaktifkan';
      case 'NO_LICENSE':       return 'Tidak Ada Lisensi';
      default:                 return 'Lisensi Berakhir';
    }
  }

  String get _description {
    switch (widget.errorCode) {
      case 'ACCOUNT_DISABLED':
        return 'Akun Anda telah dinonaktifkan oleh administrator.\nSilakan hubungi administrator untuk mengaktifkan kembali.';
      case 'NO_LICENSE':
        return 'Belum ada lisensi yang ditetapkan untuk akun ini.\nHubungi administrator untuk mendapatkan lisensi.';
      default:
        final end = widget.licenseEnd ?? 'tidak diketahui';
        return 'Masa lisensi aplikasi Anda telah berakhir pada $end.\nSilakan hubungi administrator untuk memperpanjang lisensi.';
    }
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    // Kembali ke halaman login
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C0A0A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_clock_outlined,
                        size: 54,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    _title,
                    style: GoogleFonts.inter(
                      fontSize:   28,
                      fontWeight: FontWeight.w800,
                      color:      Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color:    const Color(0xFF94A3B8),
                      height:   1.7,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _infoRow('📧', 'Email', 'adminkavier@gmail.com'),
                        const SizedBox(height: 12),
                        _infoRow('📱', 'WhatsApp', '089628959615'),
                        const SizedBox(height: 12),
                        _infoRow('🌐', 'Panel Admin', '20.39.192.91:8001/master'),
                        if (widget.licenseEnd != null) ...[
                          const SizedBox(height: 12),
                          _infoRow('📅', 'Berakhir', widget.licenseEnd!,
                              valueColor: const Color(0xFFEF4444)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _retrying ? null : _retry,
                      icon: _retrying
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _retrying ? 'Menuju Login...' : 'Kembali ke Login',
                        style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text('$label:',
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF64748B))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      valueColor ?? Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
