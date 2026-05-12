import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../utils/constants.dart';
import 'event_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final eventProv = Provider.of<EventProvider>(context);
    
    final filteredEvents = eventProv.events.where((e) {
      final title = e['title']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.all(20),
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
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search Events...',
                          hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filter options coming soon!'), behavior: SnackBarBehavior.floating),
                      );
                    },
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

            // ── Event Grid ──
            Expanded(
              child: filteredEvents.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredEvents.length,
                    itemBuilder: (_, i) => _buildGridEventCard(filteredEvents[i]),
                  ),
            ),

            // ── Suggested Events ──
            if (_searchQuery.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Related Suggested Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: eventProv.events.length > 5 ? 5 : eventProv.events.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _buildSuggestedCard(eventProv.events[i]),
                ),
              ),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Untitled';
    final venueName = event['venue']?['name'] ?? 'TBA';
    final startStr = event['start_time'];
    final date = startStr != null ? DateTime.tryParse(startStr) : null;
    final dateStr = date != null ? '${date.day}/${date.month}' : 'TBA';
    final image = event['image'];
    final imageUrl = ApiConstants.buildImageUrl(image);
    final capacity = event['capacity'] ?? 100;
    final ticketsCount = event['tickets_count'] ?? 0;
    final isSoldOut = ticketsCount >= capacity;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: AppColors.accent.withValues(alpha: 0.1), child: const Icon(Icons.image, color: AppColors.textMuted)),
                if (date != null)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)), 
                Text(venueName, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  isSoldOut ? 'Sold Out' : 'Selling Fast',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSoldOut ? AppColors.danger : AppColors.warning),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Untitled';
    final image = event['image'];
    final imageUrl = ApiConstants.buildImageUrl(image);

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity)
                : Container(color: AppColors.accent.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No events found', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
