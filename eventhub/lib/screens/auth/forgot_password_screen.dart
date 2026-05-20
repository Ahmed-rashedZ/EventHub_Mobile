import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? email;
  const ForgotPasswordScreen({super.key, this.email});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError(Provider.of<LanguageProvider>(context, listen: false).translate('enter_email_error'));
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.forgotPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(email: email),
        ),
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
                language.translate('forgot_password_title'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                language.translate('forgot_password_msg'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Text(
                language.translate('email_label'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: language.translate('send_reset_code'),
                isLoading: _isLoading,
                onPressed: _sendCode,
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
