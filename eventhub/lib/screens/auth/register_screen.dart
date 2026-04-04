import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import '../user/main_navigation.dart';

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
    final error = await auth.register(name, email, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E17), AppColors.bgDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.accent2.withValues(alpha: 0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.accent.withValues(alpha: 0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 50,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(child: Text('🎯', style: TextStyle(fontSize: 24))),
                            ),
                            const SizedBox(width: 12),
                            ShaderMask(
                              shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
                              child: const Text(
                                'EventHub',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        const Text('Join EventHub to discover events', style: TextStyle(color: AppColors.textMuted, fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        _buildLabel('Full Name'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameCtrl,
                          decoration: _inputDeco(hint: 'John Doe', icon: Icons.person_outlined),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Email Address'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailCtrl,
                          decoration: _inputDeco(hint: 'you@example.com', icon: Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passCtrl,
                          decoration: _inputDeco(hint: '••••••••', icon: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmCtrl,
                          decoration: _inputDeco(hint: '••••••••', icon: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _register(),
                        ),
                        const SizedBox(height: 28),
                        GradientButton(
                          text: 'Create Account',
                          isLoading: _isLoading,
                          onPressed: _register,
                          icon: Icons.person_add,
                          colors: [AppColors.accent2, AppColors.accent],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text('Sign In', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent2, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
