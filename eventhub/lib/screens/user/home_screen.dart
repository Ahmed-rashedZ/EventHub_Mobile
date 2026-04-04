import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/event_card.dart';
import 'event_details_screen.dart';
import '../profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'Technical', 'Workshop', 'Conference', 'Seminar', 'Cultural', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Guess filter category from event title/description
  String _guessCategory(Map<String, dynamic> event) {
    final text = '${event['title'] ?? ''} ${event['description'] ?? ''}'.toLowerCase();

    if (text.contains('tech') || text.contains('ai') || text.contains('programming') ||
        text.contains('hack') || text.contains('code') || text.contains('dev') ||
        text.contains('software') || text.contains('data') || text.contains('cyber') ||
        text.contains('تقني') || text.contains('برمج')) {
      return 'Technical';
    }
    if (text.contains('workshop') || text.contains('ورشة') || text.contains('ورشه') ||
        text.contains('hands-on') || text.contains('training') || text.contains('تدريب')) {
      return 'Workshop';
    }
    if (text.contains('conference') || text.contains('summit') || text.contains('مؤتمر')) {
      return 'Conference';
    }
    if (text.contains('seminar') || text.contains('lecture') || text.contains('talk') ||
        text.contains('ندوة') || text.contains('محاضر')) {
      return 'Seminar';
    }
    if (text.contains('cultur') || text.contains('art') || text.contains('music') ||
        text.contains('ثقاف') || text.contains('فن')) {
      return 'Cultural';
    }
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    final filtered = provider.events.where((e) {
      final title = e['title'].toString().toLowerCase();
      final venue = e['venue']?['name']?.toString().toLowerCase() ?? '';
      final desc = e['description']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      final matchesSearch = title.contains(q) || venue.contains(q) || desc.contains(q);

      if (_selectedFilter == 'All') return matchesSearch;
      return matchesSearch && _guessCategory(e) == _selectedFilter;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${auth.userName.split(' ')[0]} 👋',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Discover Events',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tappable avatar → Profile
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search events, venues...',
                    hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Filter chips
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isActive = f == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.accentGradientH : null,
                          color: isActive ? null : AppColors.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: isActive ? null : Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            // Events count + refresh
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length} Events',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => provider.fetchEvents(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.refresh, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Events list
            Expanded(
              child: provider.isLoadingEvents
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          SizedBox(height: 16),
                          Text('Loading events...', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              const Text('No events found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(
                                _selectedFilter != 'All'
                                    ? 'No "$_selectedFilter" events available'
                                    : 'Try a different search term',
                                style: const TextStyle(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = 'All';
                                    _searchQuery = '';
                                    _searchCtrl.clear();
                                  });
                                  provider.fetchEvents();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Reset & Refresh', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchEvents(),
                          color: AppColors.accent,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final event = filtered[i];
                              return EventCard(
                                event: event,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailsScreen(event: event),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
