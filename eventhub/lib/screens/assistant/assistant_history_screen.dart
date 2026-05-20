import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/constants.dart';
import 'assistant_event_details_screen.dart';

class AssistantHistoryScreen extends StatefulWidget {
  const AssistantHistoryScreen({super.key});

  @override
  State<AssistantHistoryScreen> createState() => _AssistantHistoryScreenState();
}

class _AssistantHistoryScreenState extends State<AssistantHistoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssistantProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    Provider.of<AssistantProvider>(context, listen: false).fetchHistory(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final provider = Provider.of<AssistantProvider>(context);
    final events = provider.historyEvents;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchHistory(search: _searchCtrl.text),
          color: AppColors.accent,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    language.translate('history'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Text(
                    language.translate('history_subtitle'),
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                  ),
                ),
              ),

              // ── Search Bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: language.translate('search_event_name_hint'),
                        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onSearch('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
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
                          child: Icon(Icons.history_rounded, size: 48, color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 16),
                        Text(language.translate('no_past_events'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(
                          language.translate('completed_events_msg'),
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
                      (context, index) => _buildHistoryCard(events[index], language),
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

  Widget _buildHistoryCard(Map<String, dynamic> event, LanguageProvider language) {
    final title = event['title'] ?? language.translate('untitled');
    final venue = event['venue'];
    final externalName = event['external_venue_name'];
    final externalLoc = event['external_venue_location'];

    String venueName = language.translate('tba');
    if (venue != null) {
      venueName = venue['name'] ?? language.translate('tba');
    } else if (externalName != null && externalName.toString().isNotEmpty) {
      venueName = externalName.toString();
    }
    final myScans = event['my_scans'] ?? 0;
    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    final startStr = event['start_time'];
    final date = parseApiDateTime(startStr);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = date != null ? '${months[date.month - 1]} ${date.day}, ${date.year}' : language.translate('tba');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssistantEventDetailsScreen(eventId: event['id'], eventTitle: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Event image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: imageUrl != null
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
                gradient: imageUrl == null
                    ? LinearGradient(colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent2.withValues(alpha: 0.08)])
                    : null,
              ),
              child: imageUrl == null
                  ? const Center(child: Icon(Icons.event, size: 24, color: AppColors.textMuted))
                  : null,
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(venueName, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (venue == null && externalLoc != null && externalLoc.toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 16),
                      child: GestureDetector(
                        onTap: () => _launchVenueUrl(externalLoc.toString()),
                        child: Text(
                          language.translate('open_in_maps'),
                          style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scan count badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('$myScans', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchVenueUrl(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(url)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }
}
