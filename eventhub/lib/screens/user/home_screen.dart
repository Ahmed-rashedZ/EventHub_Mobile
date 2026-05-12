import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../utils/constants.dart';
import 'event_details_screen.dart';
import 'my_tickets_screen.dart';
import 'qr_code_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  final _categories = ['All', 'Technical', 'Workshop', 'Conference', 'Seminar', 'Cultural', 'Other'];

  final Map<String, IconData> _catIcons = {
    'All': Icons.apps_rounded,
    'Technical': Icons.code_rounded,
    'Workshop': Icons.build_circle_outlined,
    'Conference': Icons.groups_rounded,
    'Seminar': Icons.school_rounded,
    'Cultural': Icons.palette_rounded,
    'Other': Icons.auto_awesome_rounded,
  };

  final Map<String, Color> _catColors = {
    'All': AppColors.accent,
    'Technical': const Color(0xFF6E40F2),
    'Workshop': const Color(0xFF22D3EE),
    'Conference': const Color(0xFFF59E0B),
    'Seminar': const Color(0xFF22C55E),
    'Cultural': const Color(0xFFEC4899),
    'Other': const Color(0xFF9CA3AF),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
      Provider.of<TicketProvider>(context, listen: false).fetchMyTickets();
    });
  }

  String _guessCategory(Map<String, dynamic> event) {
    final text = '${event['title'] ?? ''} ${event['description'] ?? ''} ${event['event_type'] ?? ''}'.toLowerCase();
    if (text.contains('tech') || text.contains('ai') || text.contains('programming') ||
        text.contains('hack') || text.contains('code') || text.contains('dev') ||
        text.contains('تقني') || text.contains('برمج')) { return 'Technical'; }
    if (text.contains('workshop') || text.contains('ورشة') || text.contains('تدريب')) { return 'Workshop'; }
    if (text.contains('conference') || text.contains('مؤتمر')) { return 'Conference'; }
    if (text.contains('seminar') || text.contains('ندوة') || text.contains('محاضر')) { return 'Seminar'; }
    if (text.contains('cultur') || text.contains('art') || text.contains('ثقاف')) { return 'Cultural'; }
    return 'Other';
  }

  List<dynamic> _filteredEvents(List<dynamic> events) {
    final now = DateTime.now();
    return events.where((e) {
      // 1. Time filter: Only show upcoming or live events (not ended)
      final endStr = e['end_time'];
      if (endStr != null) {
        try {
          final endDt = DateTime.parse(endStr);
          if (endDt.isBefore(now)) return false;
        } catch (_) {}
      } else {
        // Fallback: if no end_time, check start_time. 
        // If it started more than 24h ago, assume it's ended.
        final startStr = e['start_time'];
        if (startStr != null) {
          try {
            final startDt = DateTime.parse(startStr);
            if (startDt.add(const Duration(hours: 24)).isBefore(now)) return false;
          } catch (_) {}
        }
      }

      // 2. Category filter
      if (_selectedCategory != 'All' &&
          _guessCategory(e) != _selectedCategory) {
        return false;
      }
      // 3. Search filter
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final t = '${e['title'] ?? ''} ${e['venue']?['name'] ?? ''}'.toLowerCase();
        if (!t.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final eventProv = Provider.of<EventProvider>(context);
    final ticketProv = Provider.of<TicketProvider>(context);
    
    final name = auth.userName;
    final userImage = auth.user?['profile']?['logo'];

    final now = DateTime.now();
    final liveEvents = eventProv.events.where((e) {
      final startStr = e['start_time'];
      final endStr = e['end_time'];
      if (startStr == null) return false;
      final startDt = DateTime.tryParse(startStr);
      final endDt = endStr != null ? DateTime.tryParse(endStr) : startDt?.add(const Duration(hours: 4));
      return startDt != null && startDt.isBefore(now) && (endDt != null && endDt.isAfter(now));
    }).toList();

    final upcomingEvents = eventProv.events.where((e) {
      final startStr = e['start_time'];
      if (startStr == null) return false;
      final startDt = DateTime.tryParse(startStr);
      return startDt != null && startDt.isAfter(now);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await eventProv.fetchEvents();
            await ticketProv.fetchMyTickets();
          },
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                        backgroundImage: userImage != null ? NetworkImage(ApiConstants.buildImageUrl(userImage)!) : null,
                        child: userImage == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                            Text('Welcome to $name.', style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                      // App Logo / Notifications
                      GestureDetector(
                        onTap: () {
                          // Could open notifications or search
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.search_rounded, color: AppColors.accent2, size: 28), 
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Search & Filters ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                              suffixIcon: const Icon(Icons.tune_rounded, size: 20, color: AppColors.textMuted),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              fillColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              Text('Filters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              SizedBox(width: 8),
                              Icon(Icons.tune_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Live Events Section ──
                if (liveEvents.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Live Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: liveEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _buildLiveEventCard(liveEvents[i]),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── Upcoming Events Section ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                eventProv.isLoadingEvents
                    ? const Center(child: CircularProgressIndicator())
                    : upcomingEvents.isEmpty
                        ? _emptyStateHorizontal('No upcoming events')
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: upcomingEvents.length,
                            itemBuilder: (_, i) => _buildUpcomingEventCard(upcomingEvents[i]),
                          ),
                const SizedBox(height: 28),

                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyStateHorizontal(String msg) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Center(child: Text(msg, style: TextStyle(color: AppColors.textMuted, fontSize: 13))),
    );
  }

  Widget _buildLiveEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Untitled';
    final venueName = event['venue']?['name'] ?? 'TBA';
    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: DecorationImage(
            image: imageUrl != null ? NetworkImage(imageUrl) : const AssetImage('assets/placeholder.jpg') as ImageProvider,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Expanded(child: Text(venueName, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final event = ticket['event'] ?? {};
    final title = event['title'] ?? 'Untitled';
    final date = event['start_time'] != null ? DateTime.tryParse(event['start_time']) : null;
    final dateStr = date != null ? '${date.day}/${date.month}' : 'TBA'; 
    final status = ticket['status'] ?? 'pending';
    final isConfirmed = status == 'confirmed' || status == 'valid';

    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConfirmed 
            ? [const Color(0xFF00B4DB), const Color(0xFF0083B0)] 
            : [const Color(0xFF434343), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Date: $dateStr', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          final qrCode = ticket['qr_code']?.toString() ?? '';
                          final ticketId = ticket['id']?.toString() ?? '';
                          final isUsed = ticket['status'] == 'used';
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => QRCodeScreen(
                              qrCode: qrCode,
                              eventTitle: title,
                              ticketId: ticketId,
                              isUsed: isUsed,
                            ),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('View Tickets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // QR Code Placeholder
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.black),
                ),
              ],
            ),
          ),
          // Perforation effect
          Positioned(
            left: 190,
            top: -10,
            bottom: -10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(8, (index) => Container(
                width: 4, height: 4,
                decoration: const BoxDecoration(color: AppColors.bgDark, shape: BoxShape.circle),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Untitled';
    final venueName = event['venue']?['name'] ?? 'TBA';
    final startStr = event['start_time'];
    final date = startStr != null ? DateTime.tryParse(startStr) : null;
    final dateStr = date != null ? '${date.day}/${date.month}' : 'TBA';
    final imageUrl = ApiConstants.buildImageUrl(event['image']);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.bgCard2,
                          child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 40),
                        ),
                ),
                // Lock Icon
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_outline, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Info Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(venueName, style: TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                const Text('Selling Fast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastEventItem(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Untitled';
    final startStr = event['start_time'];
    final date = startStr != null ? DateTime.tryParse(startStr) : null;
    final dateStr = date != null ? '${date.day}/${date.month}' : 'TBA';
    final venueName = event['venue']?['name'] ?? 'TBA';
    final image = event['image'];
    final imageUrl = ApiConstants.buildImageUrl(image);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
              color: AppColors.accent.withValues(alpha: 0.1),
            ),
            child: imageUrl == null ? const Icon(Icons.image, size: 20) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(venueName, style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Rate & Review', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(5, (index) => const Icon(Icons.star_rounded, size: 14, color: AppColors.warning)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
