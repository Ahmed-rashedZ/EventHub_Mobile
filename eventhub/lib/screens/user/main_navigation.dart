import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_tickets_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../profile_screen.dart';
import '../../utils/constants.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const MyTicketsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for floating bottom bar
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
          border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.1)),
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
              _navItem(0, Icons.home_rounded),
              _navItem(1, Icons.search_rounded),
              _navItem(2, Icons.confirmation_number_rounded, hasBadge: true),
              _navItem(3, Icons.person_rounded),
              _navItem(4, Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, {bool hasBadge = false}) {
    final isActive = _currentIndex == (index > 2 ? index - 2 : index); // Mapping to 3 screens
    // Actually let's just make it simpler for the demo look
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index < _screens.length) {
          setState(() => _currentIndex = index);
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected ? AppColors.accentGradient : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.accent2.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            )
          ] : [],
        ),
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
    );
  }
}
