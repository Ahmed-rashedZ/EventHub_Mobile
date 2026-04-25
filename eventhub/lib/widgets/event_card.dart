import 'package:flutter/material.dart';
import '../utils/constants.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  String _guessCategory(Map<String, dynamic> event) {
    final text = '${event['title'] ?? ''} ${event['description'] ?? ''} ${event['event_type'] ?? ''}'.toLowerCase();
    if (text.contains('tech') || text.contains('ai') || text.contains('programming') ||
        text.contains('hack') || text.contains('code') || text.contains('dev') ||
        text.contains('تقني') || text.contains('برمج')) {
      return 'Technical';
    }
    if (text.contains('workshop') || text.contains('ورشة') || text.contains('تدريب')) {
      return 'Workshop';
    }
    if (text.contains('conference') || text.contains('مؤتمر')) {
      return 'Conference';
    }
    if (text.contains('seminar') || text.contains('ندوة') || text.contains('محاضر')) {
      return 'Seminar';
    }
    if (text.contains('cultur') || text.contains('art') || text.contains('ثقاف')) {
      return 'Cultural';
    }
    return 'Other';
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Technical': return const Color(0xFF6E40F2);
      case 'Workshop': return const Color(0xFF22D3EE);
      case 'Conference': return const Color(0xFFF59E0B);
      case 'Seminar': return const Color(0xFF22C55E);
      case 'Cultural': return const Color(0xFFEC4899);
      default: return AppColors.textMuted;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Technical': return Icons.code;
      case 'Workshop': return Icons.build_circle_outlined;
      case 'Conference': return Icons.groups_outlined;
      case 'Seminar': return Icons.school_outlined;
      case 'Cultural': return Icons.palette_outlined;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = event['title']?.toString() ?? 'Untitled Event';
    final venueName = event['venue']?['name']?.toString() ?? 'TBA';
    final category = _guessCategory(event);
    final catColor = _categoryColor(category);
    final avgRating = event['average_rating'];
    final sponsors = (event['sponsors'] as List<dynamic>?) ?? [];

    // Parse date
    final dateStr = event['start_time'];
    DateTime dt;
    try {
      dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      dt = DateTime.now();
    }
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // Status
    final now = DateTime.now();
    final isLive = dt.isBefore(now);
    final endStr = event['end_time'];
    DateTime? endDt;
    try {
      if (endStr != null) {
        endDt = DateTime.parse(endStr);
      }
    } catch (_) {}
    final isEnded = endDt != null && endDt.isBefore(now);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1F36), Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top gradient bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [catColor, catColor.withValues(alpha: 0.3)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: category + status + rating
                  Row(
                    children: [
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: catColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcon(category), size: 12, color: catColor),
                            const SizedBox(width: 4),
                            Text(
                              category,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Rating
                      if (avgRating != null && avgRating > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                              const SizedBox(width: 3),
                              Text(
                                double.parse(avgRating.toString()).toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Status badge
                      if (isEnded)
                        _statusBadge('Ended', AppColors.textMuted)
                      else if (isLive)
                        _statusBadge('Live', AppColors.success)
                      else
                        _statusBadge('Upcoming', AppColors.accent2),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // Info row
                  Row(
                    children: [
                      // Date block
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent2.withValues(alpha: 0.08)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dt.day.toString(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent, height: 1),
                            ),
                            Text(
                              months[dt.month - 1],
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(timeStr, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    venueName,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Capacity indicator
                      if (event['capacity'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                '${event['capacity']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Sponsors row
                  if (sponsors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 28,
                      child: Row(
                        children: [
                          Icon(Icons.handshake_outlined, size: 13, color: AppColors.accent2.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: sponsors.length > 3 ? 3 : sponsors.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (_, i) {
                                final s = sponsors[i];
                                final name = s['profile']?['company_name'] ?? s['name'] ?? 'Sponsor';
                                final tier = s['pivot']?['tier'] ?? 'bronze';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _tierColor(tier).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _tierColor(tier).withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tierColor(tier)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (sponsors.length > 3)
                            Text(
                              '+${sponsors.length - 3}',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.6)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'diamond': return AppColors.accent2;
      case 'gold': return AppColors.warning;
      case 'silver': return const Color(0xFF9CA3AF);
      case 'bronze': return const Color(0xFFF97316);
      default: return AppColors.textMuted;
    }
  }
}
