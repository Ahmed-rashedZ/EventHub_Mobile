import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/gradient_button.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isBooking = false;

  void _book() async {
    setState(() => _isBooking = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final error = await provider.bookTicket(widget.event['id']);

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Ticket Booked Successfully!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } else {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final dateStr = e['start_time'];
    final DateTime dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final formattedDate = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    final formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final venueName = e['venue']?['name'] ?? e['location'] ?? 'TBA';
    final venueLocation = e['venue']?['location'] ?? '';

    // Parse sponsors from event data
    final sponsors = (e['sponsors'] as List<dynamic>?) ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D1B69), Color(0xFF0F4C4C), AppColors.bgDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.accent.withValues(alpha: 0.2), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'OPEN FOR BOOKING',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success, letterSpacing: 1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            e['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards
                  _buildInfoCard(Icons.calendar_today, 'Date & Time', '$formattedDate at $formattedTime'),
                  const SizedBox(height: 12),
                  _buildInfoCard(Icons.location_on_outlined, 'Venue', '$venueName${venueLocation.isNotEmpty ? '\n$venueLocation' : ''}'),
                  const SizedBox(height: 12),
                  _buildInfoCard(Icons.people_outline, 'Capacity', '${e['capacity']} attendees'),
                  if (e['creator'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(Icons.person_outlined, 'Organized by', e['creator']?['name'] ?? 'Unknown'),
                  ],
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'About This Event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent2),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      e['description'] ?? 'No description provided.',
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
                    ),
                  ),

                  // Sponsors section
                  if (sponsors.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Event Sponsors',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent2),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sponsors.length,
                        itemBuilder: (context, i) {
                          final sponsor = sponsors[i];
                          final profile = sponsor['profile'];
                          final name = profile?['company_name'] ?? sponsor['name'] ?? 'Sponsor';
                          final logo = profile?['logo'];
                          final tier = sponsor['pivot']?['tier'] ?? 'bronze';

                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _tierColor(tier).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                if (logo != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      logo,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _defaultSponsorAvatar(name),
                                    ),
                                  )
                                else
                                  _defaultSponsorAvatar(name),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _tierColor(tier).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tier.toString().toUpperCase(),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _tierColor(tier)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  // Book button
                  GradientButton(
                    text: 'Book Ticket',
                    isLoading: _isBooking,
                    onPressed: _book,
                    icon: Icons.confirmation_number_outlined,
                    colors: [AppColors.success, const Color(0xFF16A34A)],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultSponsorAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'diamond':
        return AppColors.accent2;
      case 'gold':
        return AppColors.warning;
      case 'silver':
        return const Color(0xFF9CA3AF);
      case 'bronze':
        return const Color(0xFFF97316);
      default:
        return AppColors.textMuted;
    }
  }
}
