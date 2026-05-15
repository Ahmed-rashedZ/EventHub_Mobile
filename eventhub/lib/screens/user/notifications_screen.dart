import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/notification_provider.dart';
import '../../providers/event_provider.dart';
import 'main_navigation.dart';
import 'event_details_screen.dart';
import '../../providers/language_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language.translate('notifications'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      if (context.watch<NotificationProvider>().hasUnreadNotifications)
                        TextButton(
                          onPressed: () {
                            context.read<NotificationProvider>().markAllAsRead();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(language.translate('mark_all_read')),
                        ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.read<NotificationProvider>().fetchNotifications(),
                        child: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Notifications List ──
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  if (notificationProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5),
                    );
                  }

                  final notifications = notificationProvider.notifications;

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_rounded,
                              size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            language.translate('no_notifications'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            language.translate('notification_hint'),
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => notificationProvider.fetchNotifications(),
                    color: AppColors.accent,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(
                            notification, index, notificationProvider);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index,
      NotificationProvider provider) {
    final bool isRead = notification['isRead'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isRead ? AppColors.bgCard : AppColors.bgCard2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? AppColors.borderLight.withValues(alpha: 0.2)
              : AppColors.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Mark as read
            provider.markAsRead(index);
            // Navigate based on type
            _handleNotificationTap(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (notification['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification['icon'] as IconData,
                    color: notification['color'] as Color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isRead ? FontWeight.w600 : FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification['message'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead
                              ? AppColors.textMuted
                              : Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['time'],
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final actionType = notification['actionType'];
    final relatedId = notification['relatedId'];

    if (actionType == 'tickets') {
      final navState = context.findAncestorStateOfType<MainNavigationState>();
      navState?.setIndex(1);
    } else if (actionType == 'explore') {
      final navState = context.findAncestorStateOfType<MainNavigationState>();
      navState?.setIndex(0);
    } else if (actionType == 'event_details' && relatedId != null) {
      // Try to find the event in EventProvider
      final events = context.read<EventProvider>().events;
      final event = events.firstWhere(
        (e) => e['id'] == relatedId,
        orElse: () => {},
      );
      if (event.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EventDetailsScreen(event: event)),
        );
      }
    }
  }
}
