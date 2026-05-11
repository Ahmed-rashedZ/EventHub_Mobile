import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  void _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _showError('Please enter the verification code');
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.verifyCode(widget.email, code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == false) {
      _showError(result['message']);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            code: result['reset_token'],
          ),
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
              const Icon(Icons.mark_email_read, size: 80, color: AppColors.accent),
              const SizedBox(height: 32),
              const Text(
                'Verify Code',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code to ${widget.email}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                'VERIFICATION CODE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeCtrl,
                style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), letterSpacing: 8),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  counterText: "",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Verify Code',
                isLoading: _isLoading,
                onPressed: _verifyCode,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
