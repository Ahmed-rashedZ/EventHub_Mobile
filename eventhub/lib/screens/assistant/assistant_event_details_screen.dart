import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/constants.dart';

class AssistantEventDetailsScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const AssistantEventDetailsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<AssistantEventDetailsScreen> createState() => _AssistantEventDetailsScreenState();
}

class _AssistantEventDetailsScreenState extends State<AssistantEventDetailsScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AssistantProvider>(context, listen: false);
    final data = await provider.fetchEventStats(widget.eventId);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final event = _data?['event'] ?? {};
    final totalBooked = _data?['total_booked'] ?? 0;
    final totalScanned = _data?['total_scanned'] ?? 0;
    final myScansCount = _data?['my_scans_count'] ?? 0;
    final myScans = (_data?['my_scans'] as List<dynamic>?) ?? [];

    final venue = event['venue'];
    final externalName = event['external_venue_name'];
    final externalLoc = event['external_venue_location'];

    String venueName = language.translate('tba');
    if (venue != null) {
      venueName = venue['name'] ?? language.translate('tba');
    } else if (externalName != null && externalName.toString().isNotEmpty) {
      venueName = externalName.toString();
      if (externalLoc != null && externalLoc.toString().isNotEmpty) {
        venueName += " ($externalLoc)";
      }
    }
    final startStr = event['start_time'];
    final date = parseApiDateTime(startStr?.toString());
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = date != null ? '${months[date.month - 1]} ${date.day}, ${date.year}' : language.translate('tba');
    final timeStr = formatTo12Hour(date);

    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2D1B69), const Color(0xFF0F4C4C), AppColors.bgDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    if (imageUrl != null)
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          colorBlendMode: BlendMode.darken,
                          color: AppColors.bgDark.withValues(alpha: 0.6),
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    Positioned(
                      bottom: 0, left: 0, right: 0, height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, AppColors.bgDark],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20, bottom: 16, right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textMuted.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                             ),
                             child: Text(language.translate('completed_upper'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1)),
                           ),
                          const SizedBox(height: 8),
                          Text(
                            widget.eventTitle,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Info
                  _buildInfoCard(Icons.calendar_today, language.translate('date_time_label'), '$dateStr ${language.translate('at')} $timeStr'),
                   const SizedBox(height: 10),
                   _buildInfoCard(
                     Icons.location_on_outlined,
                     language.translate('venue_label'),
                     venueName,
                     trailing: (venue == null && externalLoc != null && externalLoc.toString().isNotEmpty)
                       ? GestureDetector(
                           onTap: () => _launchVenueUrl(externalLoc.toString()),
                           child: Text(
                             language.translate('open_in_maps'),
                             style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                           ),
                         )
                       : null,
                   ),
                   const SizedBox(height: 24),

                  // ── Statistics Section ──
                  Row(
                    children: [
                       const Icon(Icons.analytics_outlined, size: 20, color: AppColors.accent2),
                       const SizedBox(width: 8),
                       Text(language.translate('my_stats'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent2)),
                     ],
                  ),
                  const SizedBox(height: 16),

                  // Stats cards
                  Row(
                    children: [
                       _statCard(language.translate('total_booked'), totalBooked.toString(), Icons.confirmation_number_outlined, AppColors.accent),
                       const SizedBox(width: 12),
                       _statCard(language.translate('total_scanned'), totalScanned.toString(), Icons.check_circle_outline, AppColors.success),
                       const SizedBox(width: 12),
                       _statCard(language.translate('my_scans'), myScansCount.toString(), Icons.qr_code_scanner_rounded, AppColors.accent2),
                     ],
                  ),
                  const SizedBox(height: 24),

                  // ── My Scans List ──
                  if (myScans.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                           const Icon(Icons.list_alt_rounded, size: 20, color: AppColors.accent2),
                           const SizedBox(width: 8),
                           Text(language.translate('tickets_i_scanned'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent2)),
                         ]),
                         Text('${myScans.length} ${language.translate('total')}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                       ],
                    ),
                    const SizedBox(height: 12),
                    ...myScans.map((scan) => _buildScanItem(scan)),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                             const Icon(Icons.info_outline, size: 32, color: AppColors.textMuted),
                             const SizedBox(height: 8),
                             Text(language.translate('no_scans_recorded'), style: const TextStyle(color: AppColors.textMuted)),
                           ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildInfoCard(IconData icon, String label, String value, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.accent.withValues(alpha: 0.15), AppColors.accent2.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                if (trailing != null) trailing,
              ],
            ),
          ],
        )),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildScanItem(Map<String, dynamic> scan) {
    final name = scan['user_name'] ?? 'Unknown';
    final qrCode = scan['qr_code'] ?? '';
    final scannedAt = scan['scanned_at'];

    String timeStr = '';
    if (scannedAt != null) {
      timeStr = formatTo12Hour(scannedAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.check, size: 18, color: AppColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  qrCode.length > 25 ? '${qrCode.substring(0, 25)}...' : qrCode,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.6), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          if (timeStr.isNotEmpty)
            Text(timeStr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
