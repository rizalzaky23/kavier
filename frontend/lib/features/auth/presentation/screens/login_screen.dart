import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool  _obscure      = true;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // Left panel — brand
            if (MediaQuery.of(context).size.width > 800)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: AppColors.primaryGradient,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.point_of_sale_rounded,
                          size: 80, color: Colors.white),
                      const SizedBox(height: 24),
                      Text('POS App',
                          style: GoogleFonts.inter(
                            fontSize:   36,
                            fontWeight: FontWeight.w800,
                            color:      Colors.white,
                          )),
                      const SizedBox(height: 12),
                      Text('Kasir Cepat & Modern\nuntuk UMKM dan Kafe',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color:    Colors.white70,
                            height:   1.6,
                          )),
                    ],
                  ),
                ),
              ),

            // Right panel — form
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selamat Datang 👋',
                              style: GoogleFonts.inter(
                                fontSize:   28,
                                fontWeight: FontWeight.w700,
                                color:      AppColors.textPrimary,
                              )),
                          const SizedBox(height: 8),
                          Text('Masuk ke akun kasir Anda',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color:    AppColors.textSecondary,
                              )),
                          const SizedBox(height: 40),

                          // Email
                          _buildField(
                            controller: _emailCtrl,
                            label:      'Email',
                            icon:       Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                v!.isEmpty ? 'Email wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _buildField(
                            controller: _passwordCtrl,
                            label:      'Password',
                            icon:       Icons.lock_outline,
                            obscure:    _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Password wajib diisi' : null,
                          ),
                          const SizedBox(height: 8),

                          // Error
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => auth.errorMessage != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(auth.errorMessage!,
                                        style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 13)),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 28),

                          // Submit button
                          Consumer<AuthProvider>(
                            builder: (_, auth, __) => SizedBox(
                              width:  double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width:  22,
                                        child:  CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color:      Colors.white,
                                        ),
                                      )
                                    : Text('Masuk',
                                        style: GoogleFonts.inter(
                                          fontSize:   16,
                                          fontWeight: FontWeight.w600,
                                        )),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Center(
                            child: Text('Demo: admin@pos.com / password',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:    AppColors.textHint,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      obscureText:  obscure,
      keyboardType: keyboardType,
      validator:    validator,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon:   suffixIcon,
        filled:       true,
        fillColor:    AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
