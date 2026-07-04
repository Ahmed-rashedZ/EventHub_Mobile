import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/language_toggle_button.dart';
import '../user/main_navigation.dart';
import '../assistant/assistant_main_navigation.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _passwordError;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final language = Provider.of<LanguageProvider>(context, listen: false);

    if (email.isEmpty || pass.isEmpty) {
      _showError(language.translate('please_fill_all_fields'));
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.login(email, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      final localized = _localizeError(error, language);
      if (_isPasswordError(error) || localized == language.translate('wrong_password')) {
        setState(() {
          _passwordError = language.translate('wrong_password');
        });
      }
      _showError(localized);
    } else {
      if (auth.isAssistant) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AssistantMainNavigation()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNavigation()));
      }
    }
  }

  bool _isPasswordError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('password') || lower.contains('wrong password') || lower.contains('invalid credentials') || lower.contains('credentials') || lower.contains('data invalid') || lower.contains('كلمة المرور') || lower.contains('كلمة السر') || lower.contains('بيانات الاعتماد') || lower.contains('بيانات الدخل');
  }

  String _localizeError(String error, LanguageProvider language) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid credentials') || lower.contains('credentials') || lower.contains('data invalid') || lower.contains('بيانات الاعتماد') || lower.contains('بيانات الدخل')) {
      return language.translate('wrong_password');
    }
    if (lower.contains('password') || lower.contains('wrong password') || lower.contains('كلمة المرور') || lower.contains('كلمة السر')) {
      return language.translate('wrong_password');
    }
    return error;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Background Decorations ──
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          // Large subtle logo in background
          Positioned(
            left: -50,
            bottom: 50,
            child: Opacity(
              opacity: 0.03,
              child: Image.asset('assets/images/logo.png', width: 400),
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo Area
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'EventHub',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                          ),
                          Text(
                            language.translate('premium_experiences'),
                            style: const TextStyle(fontSize: 14, color: AppColors.textMuted, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Card
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(language.translate('sign_in'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 24),
                              _buildInputField(
                                controller: _emailCtrl,
                                hint: language.translate('email'),
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                controller: _passCtrl,
                                hint: language.translate('password'),
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                errorText: _passwordError,
                                onChanged: (_) {
                                  if (_passwordError != null) setState(() => _passwordError = null);
                                },
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                  child: Text(language.translate('forgot_password'), style: const TextStyle(color: AppColors.accent2, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _login,
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.accentGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(language.translate('login'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(language.translate('dont_have_account'), style: const TextStyle(color: AppColors.textMuted)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text(language.translate('create_account'), style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact Support
                    GestureDetector(
                      onTap: () async {
                        const email = 'support@eventhub.com';
                        await Clipboard.setData(const ClipboardData(text: email));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(language.translate('email_copied_to_clipboard')),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                        final uri = Uri(scheme: 'mailto', path: email);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Text(
                        language.translate('contact_support'),
                        style: const TextStyle(
                          color: AppColors.accent2,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Language Toggle Button ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: language.isArabic ? 16 : null,
            left: language.isArabic ? null : 16,
            child: const LanguageToggleButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hasError ? AppColors.danger : AppColors.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && _obscurePass,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 18),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(errorText, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
      ],
    );
  }
}
