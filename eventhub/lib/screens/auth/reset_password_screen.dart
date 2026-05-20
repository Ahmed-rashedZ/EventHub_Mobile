import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  void _resetPassword() async {
    final pass = _passCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (pass.isEmpty || confirmPass.isEmpty) {
      _showError(Provider.of<LanguageProvider>(context, listen: false).translate('please_fill_all_fields'));
      return;
    }

    if (pass != confirmPass) {
      _showError(Provider.of<LanguageProvider>(context, listen: false).translate('passwords_dont_match'));
      return;
    }

    if (pass.length < 8) {
      _showError(Provider.of<LanguageProvider>(context, listen: false).translate('password_min_length'));
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.resetPassword(widget.email, widget.code, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      // Show success message and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<LanguageProvider>(context, listen: false).translate('password_reset_success')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Image.asset('assets/images/logo.png', height: 80)),
              const SizedBox(height: 32),
              Text(
                language.translate('reset_password_title'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                language.translate('reset_password_msg'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              _buildLabel(language.translate('new_password_label')),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                obscureText: _obscurePass,
              ),
              const SizedBox(height: 20),

              _buildLabel(language.translate('confirm_password_label')),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPassCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPass = !_obscureConfirmPass,
                    ),
                  ),
                ),
                obscureText: _obscureConfirmPass,
              ),

              const SizedBox(height: 32),
              GradientButton(
                text: language.translate('reset_password_btn'),
                isLoading: _isLoading,
                onPressed: _resetPassword,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.bgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
