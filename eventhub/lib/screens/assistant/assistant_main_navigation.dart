import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/language_provider.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/auth_provider.dart';
import '../profile_screen.dart';
import 'assistant_requests_screen.dart';
import 'assistant_work_screen.dart';
import 'assistant_history_screen.dart';

class AssistantMainNavigation extends StatefulWidget {
  const AssistantMainNavigation({super.key});

  @override
  State<AssistantMainNavigation> createState() => AssistantMainNavigationState();
}

class AssistantMainNavigationState extends State<AssistantMainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final assistant = Provider.of<AssistantProvider>(context, listen: false);
      assistant.loadAvailabilityFromUser(auth.user);
    });
  }

  void setIndex(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = [
    const AssistantRequestsScreen(),
    const AssistantWorkScreen(),
    const AssistantHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.borderLight.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(0, Icons.mail_rounded, language.translate('assistance_requests')),
              _navItem(1, Icons.work_rounded, language.translate('my_work')),
              _navItem(2, Icons.history_rounded, language.translate('history')),
              _navItem(3, Icons.person_rounded, language.translate('profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String tooltip, {bool hasBadge = false}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected ? AppColors.accentGradient : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent2.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Tooltip(
          message: tooltip,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 26,
              ),
              if (hasBadge)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
