import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final size = MediaQuery.of(context).size;
    final bool showLeftPanel = size.width > 1000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ═══════════════════════════════════════════════════════════════
          // Left Side - Branded Panel (~45%)
          // ═══════════════════════════════════════════════════════════════
          if (showLeftPanel)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryColor,
                      const Color(0xFFD97706), // deeper amber
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // ── Abstract background shapes ──
                    ..._buildBackgroundShapes(),

                    // ── Content ──
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Logo
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const _AppLogo(size: 56),
                              ),
                              const SizedBox(height: 32),

                              // Title
                              Text(
                                'Construction Dashboard',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Subtitle
                              Text(
                                'Gérez vos projets, lots, équipes et journaux de chantier en temps réel.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Feature pills
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildFeatureChip(
                                    Icons.folder_outlined,
                                    'Projets',
                                  ),
                                  _buildFeatureChip(
                                    Icons.layers_outlined,
                                    'Lots',
                                  ),
                                  _buildFeatureChip(
                                    Icons.people_outline,
                                    'Équipes',
                                  ),
                                  _buildFeatureChip(
                                    Icons.article_outlined,
                                    'Journal',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ═══════════════════════════════════════════════════════════════
          // Right Side - Login Form (~55%)
          // ═══════════════════════════════════════════════════════════════
          Expanded(
            flex: showLeftPanel ? 6 : 1,
            child: Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width > 600 ? 48 : 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: EdgeInsets.all(size.width > 600 ? 44 : 28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Animated Welcome ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.0,
                              end: 0.35,
                              child: Column(
                                children: [
                                  Text(
                                    'welcome_back'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'sign_in_to_account'.tr,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),

                            // ── Email Field ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.15,
                              end: 0.50,
                              child: _buildTextField(
                                controller: _emailController,
                                label: 'email'.tr,
                                hint: 'enter_email'.tr,
                                icon: Icons.email_outlined,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'please_enter_email'.tr;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Password Field ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.25,
                              end: 0.60,
                              child: _buildPasswordField(
                                controller: _passwordController,
                                label: 'password'.tr,
                                hint: 'enter_password'.tr,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'please_enter_password'.tr;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Forgot password ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.35,
                              end: 0.65,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Get.dialog(
                                      const _ForgotPasswordDialog(),
                                      barrierDismissible: false,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Remember me ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.40,
                              end: 0.70,
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      side: BorderSide(
                                        color: const Color(0xFFD1D5DB),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Se souvenir de moi',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Sign In Button ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.50,
                              end: 0.85,
                              child: Obx(
                                () => SizedBox(
                                  height: 56,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: authController.isLoading.value
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.primaryColor
                                                    .withOpacity(0.5),
                                                AppColors.primaryColor
                                                    .withOpacity(0.5),
                                              ],
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFFF59E0B),
                                                Color(0xFFD97706),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: authController.isLoading.value
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFF59E0B,
                                                ).withOpacity(0.35),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: authController.isLoading.value
                                            ? null
                                            : () async {
                                                if (_formKey.currentState
                                                        ?.validate() ??
                                                    false) {
                                                  await authController.login(
                                                    _emailController.text,
                                                    _passwordController.text,
                                                  );
                                                }
                                              },
                                        borderRadius: BorderRadius.circular(14),
                                        child: Center(
                                          child: authController.isLoading.value
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  'sign_in'.tr,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            _AnimEntry(
                              controller: _animController,
                              begin: 0.55,
                              end: 0.90,
                              child: Obx(
                                () => SizedBox(
                                  height: 54,
                                  child: OutlinedButton(
                                    onPressed: authController.isLoading.value
                                        ? null
                                        : () async {
                                            await authController
                                                .loginWithGoogle();
                                          },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                        width: 1.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const _GoogleMark(),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Se connecter avec Google',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ── Footer ──
                            _AnimEntry(
                              controller: _animController,
                              begin: 0.60,
                              end: 1.0,
                              child: Text(
                                '© 2026 PI Project PMS — Tous droits réservés',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Background decorative shapes
  // ═══════════════════════════════════════════════════════════════════
  List<Widget> _buildBackgroundShapes() {
    return [
      // Large faint circles
      Positioned(
        left: -80,
        top: -80,
        child: Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(160),
          ),
        ),
      ),
      Positioned(
        right: -120,
        bottom: 60,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(200),
          ),
        ),
      ),
      Positioned(
        left: 80,
        bottom: -100,
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.04),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(130),
          ),
        ),
      ),
      // Subtle square
      Positioned(
        right: 60,
        top: 120,
        child: Transform.rotate(
          angle: 0.26,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      // Subtle dot
      Positioned(
        left: 140,
        top: 160,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      Positioned(
        right: 200,
        bottom: 200,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      // Building icon watermark
      Positioned(
        right: 40,
        top: 180,
        child: Opacity(
          opacity: 0.04,
          child: Icon(Icons.domain, size: 180, color: Colors.white),
        ),
      ),
      Positioned(
        left: 30,
        bottom: 180,
        child: Opacity(
          opacity: 0.03,
          child: Icon(Icons.apartment, size: 220, color: Colors.white),
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════
  // Feature chip
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Text Field
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
          validator: validator,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // Password Field
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryColor,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
          ),
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
          validator: validator,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Animated entry helper
// ═══════════════════════════════════════════════════════════════════
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 0;
  int _countdown = 0;
  Timer? _timer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendCode(AuthController controller) async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    final success = await controller.sendResetPasswordEmail(
      _emailController.text,
    );
    if (!mounted || !success) return;
    setState(() => _step = 1);
    _startCountdown();
  }

  Future<void> _verifyCode(AuthController controller) async {
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;
    final success = await controller.validateResetCode(
      _emailController.text,
      _codeController.text,
    );
    if (!mounted || !success) return;
    _timer?.cancel();
    setState(() => _step = 2);
  }

  Future<void> _resetPassword(AuthController controller) async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    final success = await controller.resetPassword(
      _emailController.text,
      _codeController.text,
      _passwordController.text,
    );
    if (!mounted || !success) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Veuillez saisir votre email';
    if (!GetUtils.isEmail(email)) return 'Veuillez saisir un email valide';
    return null;
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) return 'Veuillez saisir le code';
    if (code.length < 4) return 'Code invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Veuillez saisir un mot de passe';
    if (!_isPasswordStrong(password)) {
      return '8 caractères min., majuscule, minuscule, chiffre et symbole';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Veuillez confirmer le mot de passe';
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 22 : 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogHeader(),
                const SizedBox(height: 24),
                _buildStepIndicator(),
                const SizedBox(height: 24),
                Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildStepContent(
                      authController,
                      authController.isResetPasswordLoading.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          icon: const Icon(Icons.close_rounded),
          color: const Color(0xFF9CA3AF),
        ),
      ],
    );
  }

  String get _title {
    if (_step == 1) return 'Vérifier le code';
    if (_step == 2) return 'Nouveau mot de passe';
    return 'Mot de passe oublié';
  }

  String get _subtitle {
    if (_step == 1) return 'Entrez le code reçu par email.';
    if (_step == 2) return 'Créez un mot de passe sécurisé.';
    return 'Recevez un code de réinitialisation.';
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryColor
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(AuthController controller, bool isLoading) {
    if (_step == 1) return _codeStep(controller, isLoading);
    if (_step == 2) return _passwordStep(controller, isLoading);
    return _emailStep(controller, isLoading);
  }

  Widget _emailStep(AuthController controller, bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dialogTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'nom@exemple.com',
            icon: Icons.email_outlined,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          _primaryDialogButton(
            label: 'Envoyer le code',
            icon: Icons.send_rounded,
            isLoading: isLoading,
            onPressed: () => _sendCode(controller),
          ),
        ],
      ),
    );
  }

  Widget _codeStep(AuthController controller, bool isLoading) {
    return Form(
      key: _codeFormKey,
      child: Column(
        key: const ValueKey('code-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dialogTextField(
            controller: _codeController,
            label: 'Code de réinitialisation',
            hint: '000000',
            icon: Icons.pin_outlined,
            validator: _validateCode,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading || _countdown > 0
                  ? null
                  : () => _sendCode(controller),
              child: Text(
                _countdown > 0
                    ? 'Renvoyer dans $_countdown s'
                    : 'Renvoyer le code',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _primaryDialogButton(
            label: 'Vérifier',
            icon: Icons.check_rounded,
            isLoading: isLoading,
            onPressed: () => _verifyCode(controller),
          ),
        ],
      ),
    );
  }

  Widget _passwordStep(AuthController controller, bool isLoading) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('password-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dialogPasswordField(
            controller: _passwordController,
            label: 'Nouveau mot de passe',
            obscureText: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: _validatePassword,
          ),
          const SizedBox(height: 16),
          _dialogPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            obscureText: _obscureConfirmPassword,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: _validateConfirmPassword,
          ),
          const SizedBox(height: 22),
          _primaryDialogButton(
            label: 'Modifier le mot de passe',
            icon: Icons.save_outlined,
            isLoading: isLoading,
            onPressed: () => _resetPassword(controller),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: _dialogInputDecoration(hint, icon),
        ),
      ],
    );
  }

  Widget _dialogPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          decoration: _dialogInputDecoration('••••••••', Icons.lock_outline)
              .copyWith(
                suffixIcon: IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Widget _primaryDialogButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _AnimEntry extends StatelessWidget {
  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  const _AnimEntry({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared App Logo widget
// ═══════════════════════════════════════════════════════════════════
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.inter(
            color: const Color(0xFF4285F4),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  final double size;

  const _AppLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final circleSize = size * 0.60;
    final fontSize = size * 0.30;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Center(
        child: Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'PI',
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
