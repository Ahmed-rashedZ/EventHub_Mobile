import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class AssistantRequestsScreen extends StatefulWidget {
  const AssistantRequestsScreen({super.key});

  @override
  State<AssistantRequestsScreen> createState() => _AssistantRequestsScreenState();
}

class _AssistantRequestsScreenState extends State<AssistantRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssistantProvider>(context, listen: false).fetchRequests();
    });
  }

  void _respond(int requestId, String status) async {
    if (status == 'rejected') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 10),
              Text('Reject Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to reject this invitation?',
            style: TextStyle(color: AppColors.textMuted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final provider = Provider.of<AssistantProvider>(context, listen: false);
    final error = await provider.respondToRequest(requestId, status);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ]),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      final msg = status == 'accepted' ? 'Invitation accepted! 🎉' : 'Invitation rejected';
      final color = status == 'accepted' ? AppColors.success : AppColors.textMuted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(status == 'accepted' ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(msg),
          ]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssistantProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final requests = provider.requests;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchRequests(),
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                        child: Text(
                          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                            const Text('Assistant', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.accent2, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'EventHub',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Title ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Text(
                    'Assistance Requests',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),

              // ── Content ──
              if (provider.isLoading && requests.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                )
              else if (requests.isEmpty)
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
                          child: Icon(Icons.inbox_rounded, size: 48, color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No Pending Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          'New invitations will appear here',
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
                      (context, index) {
                        final req = requests[index];
                        return _buildRequestCard(req);
                      },
                      childCount: requests.length,
                    ),
                  ),
                ),

              // Bottom space for nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final event = req['event'] ?? {};
    final manager = req['manager'] ?? {};
    final title = event['title'] ?? 'Untitled Event';
    final venueName = event['venue']?['name'] ?? 'TBA';
    final managerName = manager['name'] ?? 'Unknown';
    final message = req['message'];
    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    final startStr = event['start_time'];
    final date = startStr != null ? DateTime.tryParse(startStr) : null;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = date != null ? '${months[date.month - 1]} ${date.day}, ${date.year}' : 'TBA';
    final timeStr = date != null ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image header
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
                color: Colors.black.withValues(alpha: 0.3),
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent.withValues(alpha: 0.2), AppColors.accent2.withValues(alpha: 0.1)],
                    ),
                  ),
                  child: const Center(child: Icon(Icons.event, size: 40, color: AppColors.textMuted)),
                ),
              ),
            )
          else
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                gradient: LinearGradient(
                  colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent2.withValues(alpha: 0.08)],
                ),
              ),
              child: const Center(child: Icon(Icons.event_available, size: 36, color: AppColors.textMuted)),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),

                // Info rows
                _infoRow(Icons.calendar_today_rounded, '$dateStr $timeStr'),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, venueName),
                const SizedBox(height: 6),
                _infoRow(Icons.person_outline_rounded, 'From: $managerName'),

                // Message
                if (message != null && message.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.message_outlined, size: 16, color: AppColors.accent.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.toString(),
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _respond(req['id'], 'rejected'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, size: 20, color: AppColors.danger),
                              SizedBox(width: 6),
                              Text('Reject', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _respond(req['id'], 'accepted'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF16A34A)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 20, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Accept', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
