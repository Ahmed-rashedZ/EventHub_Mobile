import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'event_details_screen.dart';

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
    return events.where((e) {
      if (_selectedCategory != 'All' && _guessCategory(e) != _selectedCategory) { return false; }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final t = '${e['title'] ?? ''} ${e['description'] ?? ''} ${e['venue']?['name'] ?? ''}'.toLowerCase();
        if (!t.contains(q)) { return false; }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final eventProv = Provider.of<EventProvider>(context);
    final filtered = _filteredEvents(eventProv.events);
    final name = auth.userName;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello, $name 👋', style: TextStyle(fontSize: 14, color: AppColors.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            const Text('Discover Events', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // ── Search Bar ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search events, venues...',
                        hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Category Filters ──
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final isActive = _selectedCategory == cat;
                        final color = _catColors[cat] ?? AppColors.accent;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: 8, left: i == 0 ? 0 : 0),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: isActive ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)]) : null,
                              color: isActive ? null : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isActive ? Colors.transparent : AppColors.border),
                              boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_catIcons[cat], size: 15, color: isActive ? Colors.white : AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(cat, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? Colors.white : AppColors.textMuted)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Results count ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('${filtered.length} Events', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => eventProv.fetchEvents(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                          child: Icon(eventProv.isLoadingEvents ? Icons.hourglass_top : Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Event List ──
            Expanded(
              child: eventProv.isLoadingEvents
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5))
                  : eventProv.errorMessage != null
                      ? _emptyState(eventProv.errorMessage!, Icons.wifi_off_rounded)
                      : filtered.isEmpty
                          ? _emptyState('No events found', Icons.event_busy_rounded)
                          : RefreshIndicator(
                              onRefresh: () => eventProv.fetchEvents(),
                              color: AppColors.accent,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _buildEventCard(filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle),
          child: Icon(icon, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 16),
        Text(msg, style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 15)),
      ]),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title']?.toString() ?? 'Untitled';
    final venueName = event['venue']?['name']?.toString() ?? 'TBA';
    final desc = event['description']?.toString() ?? '';
    final category = _guessCategory(event);
    final catColor = _catColors[category] ?? AppColors.textMuted;
    final avgRating = event['average_rating'];
    final image = event['image'];
    final capacity = event['capacity'];
    final ticketsCount = event['tickets_count'];

    final dateStr = event['start_time'];
    DateTime dt;
    try { dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now(); } catch (_) { dt = DateTime.now(); }
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final endStr = event['end_time'];
    DateTime? endDt;
    try { if (endStr != null) { endDt = DateTime.parse(endStr); } } catch (_) {}
    final isEnded = endDt != null && endDt.isBefore(now);
    final isLive = !isEnded && dt.isBefore(now);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / Gradient Header ──
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                gradient: image == null ? LinearGradient(
                  colors: [catColor.withValues(alpha: 0.25), AppColors.bgCard],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ) : null,
                image: image != null ? DecorationImage(
                  image: NetworkImage(image.toString().startsWith('http') ? image : 'http://127.0.0.1:8000/storage/$image'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
                ) : null,
              ),
              child: Stack(
                children: [
                  // Decorative circles when no image
                  if (image == null) ...[
                    Positioned(right: -20, top: -20, child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: catColor.withValues(alpha: 0.08)),
                    )),
                    Positioned(left: 20, bottom: 20, child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent2.withValues(alpha: 0.06)),
                    )),
                    // Big icon
                    Center(child: Icon(_catIcons[category], size: 50, color: catColor.withValues(alpha: 0.15))),
                  ],
                  // Top badges
                  Positioned(
                    top: 12, left: 12, right: 12,
                    child: Row(
                      children: [
                        _chip(category, catColor, icon: _catIcons[category]),
                        const Spacer(),
                        if (avgRating != null && (avgRating is num ? avgRating > 0 : double.tryParse(avgRating.toString()) != null && double.parse(avgRating.toString()) > 0))
                          _chip(double.parse(avgRating.toString()).toStringAsFixed(1), AppColors.warning, icon: Icons.star_rounded),
                        if (avgRating != null && (avgRating is num ? avgRating > 0 : double.tryParse(avgRating.toString()) != null && double.parse(avgRating.toString()) > 0))
                          const SizedBox(width: 6),
                        if (isEnded)
                          _chip('Ended', AppColors.textMuted)
                        else if (isLive)
                          _chip('Live', AppColors.success, glow: true)
                        else
                          _chip('Upcoming', AppColors.accent2),
                      ],
                    ),
                  ),
                  // Date block
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(children: [
                        Text(dt.day.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent, height: 1)),
                        Text(months[dt.month - 1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // ── Content ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(desc, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.7), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  // Info row
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(timeStr, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 14),
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(venueName, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      if (capacity != null) ...[
                        Icon(Icons.people_outline, size: 14, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text('${ticketsCount ?? 0}/$capacity', style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.6))),
                      ],
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

  Widget _chip(String text, Color color, {IconData? icon, bool glow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)] : [],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
