import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_tickets_screen.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../profile_screen.dart';
import 'notifications_screen.dart';
import '../../utils/constants.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import 'event_details_screen.dart';
import '../../services/fcm_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  StreamSubscription? _foregroundSub;
  StreamSubscription? _tapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeepLink();
      _listenToFCM();
      _checkInitialNotification();
    });
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    super.dispose();
  }

  void _listenToFCM() {
    final notificationProvider = context.read<NotificationProvider>();

    // Foreground message: auto-refresh notification list & badge
    _foregroundSub = FCMService.onForegroundMessage.listen((_) {
      notificationProvider.fetchNotifications();
    });

    // Notification tap: navigate to the relevant screen
    _tapSub = FCMService.onNotificationTap.listen((data) {
      _handleNotificationNavigation(data);
    });
  }

  void _checkInitialNotification() async {
    final data = await FCMService.getInitialNotification();
    if (data != null && mounted) {
      _handleNotificationNavigation(data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? relatedIdStr = data['related_id'];
    final int? relatedId = relatedIdStr != null ? int.tryParse(relatedIdStr) : null;

    // Pop any open dialogs/screens so we are back at MainNavigation
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if (type == 'ticket') {
      setIndex(1);
    } else if (type == 'event') {
      if (relatedId != null) {
        _navigateToEventDetails(relatedId);
      } else {
        setIndex(0);
      }
    } else {
      setIndex(4);
    }
  }

  void _navigateToEventDetails(int eventId) async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final event = await eventProvider.fetchEventDetail(eventId);
    if (event != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
      );
    }
  }

  void _checkDeepLink() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.pendingEventId != null) {
      final eventId = auth.pendingEventId!;
      auth.pendingEventId = null; // Clear it immediately

      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final event = await eventProvider.fetchEventDetail(eventId);

      if (event != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
        );
      }
    }
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyTicketsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
    const NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final hasUnreadTickets = context.watch<TicketProvider>().hasUnreadTickets;
    final hasUnreadNotifications =
        context.watch<NotificationProvider>().hasUnreadNotifications;

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
              _navItem(0, Icons.home_rounded),
              _navItem(
                1,
                Icons.confirmation_number_rounded,
                hasBadge: hasUnreadTickets,
              ),
              _navItem(
                4,
                Icons.notifications_rounded,
                hasBadge: hasUnreadNotifications,
              ),
              _navItem(2, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, {bool hasBadge = false}) {
    // Highlight Profile (index 2) if we are in Settings (index 3)
    final isSelected =
        _currentIndex == index || (_currentIndex == 3 && index == 2);

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
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.accent2.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
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
