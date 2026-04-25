import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/event_provider.dart';

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
  int _userRating = 0;
  bool _isRating = false;
  final _reviewCtrl = TextEditingController();
  List<dynamic> _reviews = [];
  double _avgRating = 0;
  int _totalReviews = 0;
  bool _loadingReviews = false;
  bool _hasTicket = false;

  @override
  void initState() {
    super.initState();
    _avgRating = double.tryParse(widget.event['average_rating']?.toString() ?? '0') ?? 0;
    _loadReviews();
    _checkTicket();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  void _checkTicket() {
    final tickets = Provider.of<TicketProvider>(context, listen: false).myTickets;
    final eventId = widget.event['id'];
    _hasTicket = tickets.any((t) => t['event']?['id'] == eventId);
  }

  void _loadReviews() async {
    setState(() => _loadingReviews = true);
    final provider = Provider.of<EventProvider>(context, listen: false);
    final data = await provider.fetchReviews(widget.event['id']);
    if (data != null && mounted) {
      setState(() {
        _reviews = data['reviews'] ?? data['data'] ?? [];
        if (data['average_rating'] != null) {
          _avgRating = double.tryParse(data['average_rating'].toString()) ?? _avgRating;
        }
        _totalReviews = _reviews.length;
      });
    }
    if (mounted) setState(() => _loadingReviews = false);
  }

  void _book() async {
    setState(() => _isBooking = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final error = await provider.bookTicket(widget.event['id']);
    if (!mounted) return;
    setState(() => _isBooking = false);

    if (error == null) {
      setState(() => _hasTicket = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Ticket Booked Successfully!'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
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
    }
  }

  void _submitRating() async {
    if (_userRating == 0) return;
    setState(() => _isRating = true);
    final provider = Provider.of<EventProvider>(context, listen: false);
    final error = await provider.rateEvent(
      widget.event['id'],
      _userRating,
      reviewText: _reviewCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isRating = false);

    if (error == null) {
      _reviewCtrl.clear();
      _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.star_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Rating submitted!'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final dateStr = e['start_time'];
    final DateTime dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final formattedDate = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    final formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final venueName = e['venue']?['name'] ?? e['location'] ?? 'TBA';
    final venueLocation = e['venue']?['location'] ?? '';
    final sponsors = (e['sponsors'] as List<dynamic>?) ?? [];
    final isStarted = dt.isBefore(DateTime.now());
    final canRate = _hasTicket && isStarted;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar
          SliverAppBar(
            expandedHeight: 240,
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D1B69), Color(0xFF0F4C4C), AppColors.bgDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(right: -40, top: -40, child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
                        colors: [AppColors.accent.withValues(alpha: 0.2), Colors.transparent],
                      )),
                    )),
                    Positioned(left: -30, bottom: 80, child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
                        colors: [AppColors.accent2.withValues(alpha: 0.12), Colors.transparent],
                      )),
                    )),
                    Positioned(
                      left: 20, bottom: 20, right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status + Rating row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isStarted ? AppColors.accent2 : AppColors.success).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: (isStarted ? AppColors.accent2 : AppColors.success).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  isStarted ? 'STARTED' : 'OPEN FOR BOOKING',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isStarted ? AppColors.accent2 : AppColors.success, letterSpacing: 1),
                                ),
                              ),
                              if (_avgRating > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 3),
                                    Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                    Text(' ($_totalReviews)', style: TextStyle(fontSize: 10, color: AppColors.warning.withValues(alpha: 0.7))),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            e['title'] ?? 'Untitled',
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
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _sectionTitle('About This Event', Icons.article_outlined),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
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
                    _sectionTitle('Event Sponsors', Icons.handshake_outlined),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sponsors.length,
                        itemBuilder: (_, i) => _buildSponsorCard(sponsors[i]),
                      ),
                    ),
                  ],
                  // Rating section
                  if (canRate) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Rate This Event', Icons.star_outline_rounded),
                    const SizedBox(height: 12),
                    _buildRatingInput(),
                  ],
                  // Reviews section
                  if (_reviews.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Reviews ($_totalReviews)', Icons.rate_review_outlined),
                    const SizedBox(height: 12),
                    ..._reviews.take(5).map((r) => _buildReviewCard(r)),
                  ] else if (_loadingReviews) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
                  ],
                  const SizedBox(height: 32),
                  // Book button
                  if (!isStarted)
                    GradientButton(
                      text: _hasTicket ? 'Already Booked ✓' : 'Book Ticket',
                      isLoading: _isBooking,
                      onPressed: _hasTicket ? () {} : _book,
                      icon: _hasTicket ? Icons.check_circle : Icons.confirmation_number_outlined,
                      colors: _hasTicket
                          ? [AppColors.textMuted, AppColors.textMuted]
                          : [AppColors.success, const Color(0xFF16A34A)],
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

  Widget _sectionTitle(String text, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppColors.accent2, size: 20),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent2)),
    ]);
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
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
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        )),
      ]),
    );
  }

  Widget _buildSponsorCard(Map<String, dynamic> sponsor) {
    final profile = sponsor['profile'];
    final name = profile?['company_name'] ?? sponsor['name'] ?? 'Sponsor';
    final logo = profile?['logo'];
    final tier = sponsor['pivot']?['tier'] ?? 'bronze';
    final tColor = _tierColor(tier);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [tColor.withValues(alpha: 0.08), AppColors.bgCard]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tColor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        if (logo != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(logo, width: 42, height: 42, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarBox(name, tColor)),
          )
        else _avatarBox(name, tColor),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: tColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(tier.toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tColor)),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _avatarBox(String name, Color color) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white))),
    );
  }

  Widget _buildRatingInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1F36), Color(0xFF161B22)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _userRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  i < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 36,
                  color: i < _userRating ? AppColors.warning : AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
            )),
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reviewCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write a review (optional)...',
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              text: 'Submit Rating',
              isLoading: _isRating,
              onPressed: _submitRating,
              icon: Icons.send_rounded,
              colors: [AppColors.warning, const Color(0xFFD97706)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final userName = review['user']?['name'] ?? 'Anonymous';
    final rating = review['rating'] ?? 0;
    final text = review['review_text'] ?? '';
    final date = review['created_at'];
    String dateStr = '';
    if (date != null) {
      final dt = DateTime.tryParse(date);
      if (dt != null) {
        final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        dateStr = '${months[dt.month-1]} ${dt.day}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
            child: Center(child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(
            i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14, color: i < rating ? AppColors.warning : AppColors.textMuted.withValues(alpha: 0.3),
          ))),
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
        ],
      ]),
    );
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'diamond': return AppColors.accent2;
      case 'gold': return AppColors.warning;
      case 'silver': return const Color(0xFF9CA3AF);
      case 'bronze': return const Color(0xFFF97316);
      default: return AppColors.textMuted;
    }
  }
}
