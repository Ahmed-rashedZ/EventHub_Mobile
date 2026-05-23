import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../providers/language_provider.dart';
import '../auth/login_screen.dart';
import '../auth/forgot_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(language.translate('settings')),
        leading: IconButton(
          icon: Icon(
            language.isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(language.translate('account'), [
              _buildSettingItem(Icons.alternate_email_rounded, language.translate('change_email'), onTap: () => _showChangeEmailDialog(context, auth, language)),
              _buildSettingItem(Icons.lock_outline_rounded, language.translate('change_password'), onTap: () => _showChangePasswordDialog(context, language)),
            ]),
            _buildSection(language.translate('notifications'), [
              _buildSettingItem(Icons.notifications_active_outlined, language.translate('push_notifications'), 
                trailing: Switch.adaptive(
                  value: _pushNotifications, 
                  onChanged: (v) => setState(() => _pushNotifications = v),
                  activeColor: AppColors.accent2,
                ),
              ),
            ]),
            _buildSection(language.translate('app_preferences'), [
              _buildSettingItem(Icons.language_rounded, language.translate('language'),
                trailing: Text(
                  '${language.isArabic ? 'العربية' : 'English'} >',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                onTap: () => _showLanguageSheet(context, language),
              ),
            ]),
            _buildSection(language.translate('about'), [
              _buildSettingItem(Icons.info_outline_rounded, '${language.translate('version')} 0.0.1'),
            ]),
            const SizedBox(height: 32),
            
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: GestureDetector(
                onTap: () => _showLogoutDialog(context, auth, language),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(language.translate('logout'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textMuted.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textMuted),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$title is not implemented yet'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ));
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth, LanguageProvider language) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(language.translate('logout'), style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(language.translate('confirm_logout'), style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(language.translate('cancel'), style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(language.translate('logout'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, AuthProvider auth, LanguageProvider language) {
    final currentEmailCtrl = TextEditingController(text: auth.userEmail);
    final newEmailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(language.translate('change_email'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.translate('verify_identity'),
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                _dialogLabel(language.translate('current_email')),
                const SizedBox(height: 6),
                _dialogInput(currentEmailCtrl, language.translate('current_email'), false),
                const SizedBox(height: 16),
                _dialogLabel(language.translate('new_email')),
                const SizedBox(height: 6),
                _dialogInput(newEmailCtrl, language.translate('new_email'), false),
                const SizedBox(height: 16),
                _dialogLabel(language.translate('current_password')),
                const SizedBox(height: 6),
                _dialogInput(passwordCtrl, language.translate('current_password'), true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(language.translate('cancel'),
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newEmailCtrl.text.trim().isEmpty) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final api = ApiService();
                        final res = await api.put('/profile', {
                          'email': newEmailCtrl.text.trim(),
                          'current_email': currentEmailCtrl.text.trim(),
                          'password': passwordCtrl.text.trim(),
                        });

                        if (res.statusCode == 200) {
                          await auth.checkAuth();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                content: Text(language.translate('email_updated')),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          final data = jsonDecode(res.body);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    data['message'] ?? 'Failed to update email'),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      }
                      setDialogState(() => isLoading = false);
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(language.translate('change'),
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5));
  }

  void _showChangePasswordDialog(BuildContext context, LanguageProvider language) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(language.translate('change_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(language.translate('verify_identity'), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            _dialogInput(currentCtrl, language.translate('current_password'), true),
            const SizedBox(height: 12),
            _dialogInput(newCtrl, language.translate('new_password'), true),
            const SizedBox(height: 12),
            _dialogInput(confirmCtrl, language.translate('confirm_password'), true),
            const SizedBox(height: 12),
            Align(
              alignment: language.isArabic ? Alignment.centerLeft : Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen(email: auth.userEmail)));
                },
                child: Text(language.translate('forgot_password'), style: const TextStyle(color: AppColors.accent2, fontSize: 13)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(language.translate('cancel'), style: const TextStyle(color: AppColors.textMuted))),
          TextButton(
            onPressed: () {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(language.translate('passwords_not_match')), backgroundColor: AppColors.danger));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(language.translate('password_updated')), backgroundColor: AppColors.success));
            }, 
            child: Text(language.translate('update'), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _dialogInput(TextEditingController ctrl, String hint, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, LanguageProvider language) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(language.translate('select_language'), style: const TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            title: Text(language.translate('english')),
            trailing: !language.isArabic ? const Icon(Icons.check, color: AppColors.accent2) : null,
            onTap: () {
              language.setLanguage('en');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(language.translate('arabic')),
            trailing: language.isArabic ? const Icon(Icons.check, color: AppColors.accent2) : null,
            onTap: () {
              language.setLanguage('ar');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'EventHub',
      applicationVersion: '2.3.1',
      applicationLegalese: '© 2026 EventHub Team. All rights reserved.',
    );
  }
}
