import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assistant_provider.dart';
import '../../utils/constants.dart';
import 'assistant_event_work_screen.dart';

class AssistantWorkScreen extends StatefulWidget {
  const AssistantWorkScreen({super.key});

  @override
  State<AssistantWorkScreen> createState() => _AssistantWorkScreenState();
}

class _AssistantWorkScreenState extends State<AssistantWorkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssistantProvider>(context, listen: false).fetchWorkEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssistantProvider>(context);
    final events = provider.workEvents;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchWorkEvents(),
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Header ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'My Work',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Text(
                    'Events you\'re assigned to assist',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
              ),

              // ── Content ──
              if (provider.isLoading && events.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                )
              else if (events.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.1),
                          ),
                          child: Icon(Icons.work_off_rounded, size: 48, color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No Active Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          'Accept invitations to see events here',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildWorkEventCard(events[index]),
                      childCount: events.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Untitled';
    final venueName = event['venue']?['name'] ?? 'TBA';
    final timeStatus = event['time_status'] ?? 'upcoming';
    final isLive = timeStatus == 'live';
    final totalTickets = event['total_tickets'] ?? 0;
    final scannedTickets = event['scanned_tickets'] ?? 0;
    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    final startStr = event['start_time'];
    final date = parseApiDateTime(startStr);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = date != null ? '${months[date.month - 1]} ${date.day}' : 'TBA';
    final timeStr = formatTo12Hour(date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssistantEventWorkScreen(eventId: event['id'], eventTitle: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isLive ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: imageUrl != null
                      ? Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover,
                          colorBlendMode: BlendMode.darken,
                          color: Colors.black.withValues(alpha: 0.3),
                          errorBuilder: (_, __, ___) => _placeholderImage())
                      : _placeholderImage(),
                ),
                // Status badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLive ? AppColors.success : AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isLive ? 'LIVE' : 'UPCOMING',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text('$dateStr $timeStr', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(venueName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Scan progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Scanned', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                Text('$scannedTickets / $totalTickets', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalTickets > 0 ? (scannedTickets / totalTickets).clamp(0.0, 1.0) : 0.0,
                                minHeight: 6,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(isLive ? AppColors.success : AppColors.accent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent2.withValues(alpha: 0.08)],
        ),
      ),
      child: const Center(child: Icon(Icons.event, size: 36, color: AppColors.textMuted)),
    );
  }
}
