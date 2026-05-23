import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/constants.dart';
import '../user/event_details_screen.dart';

class AssistantRequestsScreen extends StatefulWidget {
  const AssistantRequestsScreen({super.key});

  @override
  State<AssistantRequestsScreen> createState() =>
      _AssistantRequestsScreenState();
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
        builder:
            (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).translate('reject_invitation'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                Provider.of<LanguageProvider>(
                  context,
                  listen: false,
                ).translate('reject_invitation_msg'),
                style: const TextStyle(color: AppColors.textMuted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).translate('cancel'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).translate('reject'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      final language = Provider.of<LanguageProvider>(context, listen: false);
      final msg =
          status == 'accepted'
              ? language.translate('invitation_accepted')
              : language.translate('invitation_rejected');
      final color =
          status == 'accepted' ? AppColors.success : AppColors.textMuted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'accepted' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(msg),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _launchVenueUrl(String url) async {
    try {
      final uri = Uri.parse(
        url.startsWith('http')
            ? url
            : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(url)}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
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
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Title ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Text(
                    language.translate('assistance_requests'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // ── Content ──
              if (provider.isLoading && requests.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
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
                          child: Icon(
                            Icons.inbox_rounded,
                            size: 48,
                            color: AppColors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          language.translate('no_pending_requests'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.translate('new_invitations_msg'),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final req = requests[index];
                      return _buildRequestCard(req, language);
                    }, childCount: requests.length),
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

  Widget _buildRequestCard(
    Map<String, dynamic> req,
    LanguageProvider language,
  ) {
    final event = req['event'] ?? {};
    final manager = req['manager'] ?? {};
    final title = event['title'] ?? language.translate('untitled_event');
    final venue = event['venue'];
    final externalName = event['external_venue_name'];
    final externalLoc = event['external_venue_location'];

    String venueName = language.translate('tba');
    if (venue != null) {
      venueName = venue['name'] ?? language.translate('tba');
    } else if (externalName != null && externalName.toString().isNotEmpty) {
      venueName = externalName.toString();
    }
    final managerName = manager['name'] ?? 'Unknown';
    final message = req['message'];
    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    final startStr = event['start_time'];
    final date = parseApiDateTime(startStr);
    final months = [
      language.translate('jan'),
      language.translate('feb'),
      language.translate('mar'),
      language.translate('apr'),
      language.translate('may'),
      language.translate('jun'),
      language.translate('jul'),
      language.translate('aug'),
      language.translate('sep'),
      language.translate('oct'),
      language.translate('nov'),
      language.translate('dec'),
    ];
    final dateStr =
        date != null
            ? '${months[date.month - 1]} ${date.day}, ${date.year}'
            : language.translate('tba');
    final timeStr = formatTo12Hour(date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image header
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  colorBlendMode: BlendMode.darken,
                  color: Colors.black.withValues(alpha: 0.3),
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.2),
                              AppColors.accent2.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.event,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.15),
                      AppColors.accent2.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.event_available,
                    size: 36,
                    color: AppColors.textMuted,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info rows
                  _infoRow(Icons.calendar_today_rounded, '$dateStr $timeStr'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venueName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (venue == null &&
                      externalLoc != null &&
                      externalLoc.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 18),
                      child: GestureDetector(
                        onTap: () => _launchVenueUrl(externalLoc.toString()),
                        child: Text(
                          language.translate('open_in_maps'),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.person_outline_rounded,
                    '${language.translate('from')} $managerName',
                  ),

                  // Message
                  if (message != null && message.toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.message_outlined,
                            size: 16,
                            color: AppColors.accent.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
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
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  language.translate('reject'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
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
                              gradient: const LinearGradient(
                                colors: [AppColors.success, Color(0xFF16A34A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  language.translate('accept'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
