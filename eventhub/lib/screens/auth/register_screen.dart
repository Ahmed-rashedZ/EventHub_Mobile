import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import '../user/main_navigation.dart';
import '../assistant/assistant_main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'User'; // 'User' or 'Assistant'

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showError('Please fill all fields');
      return;
    }
    if (pass.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (pass != confirm) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.register(name, email, pass, role: _selectedRole);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      Widget destination;
      if (_selectedRole == 'Assistant') {
        destination = const AssistantMainNavigation();
      } else {
        destination = const MainNavigation();
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    }
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
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.accent2.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: -50,
            bottom: -50,
            child: Opacity(
              opacity: 0.03,
              child: const Icon(Icons.person_add_rounded, size: 400, color: Colors.white),
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Logo Area
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                        boxShadow: [
                          BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                        ],
                      ),
                      child: Image.asset('assets/images/logo.png', height: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(language.translate('join_eventhub'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text(language.translate('create_premium_account'), style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
                    const SizedBox(height: 24),

                    // ── Role Selection Toggle ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildRoleTab(language.translate('user_role'), Icons.person_rounded, 'User'),
                          _buildRoleTab(language.translate('assistant_role'), Icons.qr_code_scanner_rounded, 'Assistant'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInputField(controller: _nameCtrl, hint: language.translate('full_name_label'), icon: Icons.person_outline_rounded),
                          const SizedBox(height: 16),
                          _buildInputField(controller: _emailCtrl, hint: language.translate('email_label'), icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildInputField(controller: _passCtrl, hint: language.translate('password_label'), icon: Icons.lock_outline_rounded, isPassword: true),
                          const SizedBox(height: 16),
                          _buildInputField(controller: _confirmCtrl, hint: language.translate('confirm_password_label'), icon: Icons.lock_reset_rounded, isPassword: true, isConfirm: true),
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap: _register,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(language.translate('create_account_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(language.translate('already_have_account_msg'), style: const TextStyle(color: AppColors.textMuted)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(language.translate('sign_in'), style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? (isConfirm ? _obscureConfirm : _obscurePass) : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
          suffixIcon: isPassword ? IconButton(
            icon: Icon((isConfirm ? _obscureConfirm : _obscurePass) ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 18),
            onPressed: () => setState(() {
              if (isConfirm) _obscureConfirm = !_obscureConfirm;
              else _obscurePass = !_obscurePass;
            }),
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, IconData icon, String role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
