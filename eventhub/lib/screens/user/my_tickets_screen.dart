import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../utils/constants.dart';
import 'qr_code_screen.dart';
import 'event_details_screen.dart';
import '../../providers/language_provider.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});
  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  List<dynamic> _filterTickets(List<dynamic> tickets) {
    if (_search.isEmpty) return tickets;
    final q = _search.toLowerCase();
    return tickets.where((t) {
      final event = t['event'] ?? {};
      final title = (event['title'] ?? '').toString().toLowerCase();
      final venue = (event['venue']?['name'] ?? event['external_venue_name'] ?? '').toString().toLowerCase();
      return title.contains(q) || venue.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchMyTickets();
      Provider.of<TicketProvider>(context, listen: false).markTicketsAsRead();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProv = Provider.of<TicketProvider>(context);
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(child: Text(language.translate('my_tickets'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
                  GestureDetector(
                    onTap: () => ticketProv.fetchMyTickets(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
                      child: Icon(ticketProv.isLoadingTickets ? Icons.hourglass_top : Icons.refresh_rounded, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Search Field ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '${language.translate('search')}...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Segmented Control Tab Bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
              child: TabBar(
                controller: _tabCtrl,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: AppColors.bgCard2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(text: '${language.translate('upcoming_events')} (${_filterTickets(ticketProv.upcomingTickets).length})'),
                  Tab(text: '${language.translate('history')} (${_filterTickets(ticketProv.pastTickets).length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Ticket List ──
            Expanded(
              child: ticketProv.isLoadingTickets
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2.5))
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildTicketList(_filterTickets(ticketProv.upcomingTickets), isUpcoming: true),
                        _buildTicketList(_filterTickets(ticketProv.pastTickets), isUpcoming: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<dynamic> tickets, {required bool isUpcoming}) {
    final language = Provider.of<LanguageProvider>(context);
    if (tickets.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.bgCard, shape: BoxShape.circle),
            child: Icon(
              isUpcoming ? Icons.confirmation_number_outlined : Icons.history_rounded,
              size: 48, color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isUpcoming ? language.translate('no_upcoming_events') : language.translate('no_history'),
            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 15),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 8),
            Text(language.translate('book_ticket_hint'), style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 13)),
          ],
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => Provider.of<TicketProvider>(context, listen: false).fetchMyTickets(),
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: tickets.length,
        itemBuilder: (_, i) => _buildTicketCard(tickets[i], isUpcoming: isUpcoming),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, {required bool isUpcoming}) {
    final language = Provider.of<LanguageProvider>(context);
    final event = ticket['event'] as Map<String, dynamic>? ?? {};
    final title = event['title']?.toString() ?? 'Unknown Event';
    final qrCode = ticket['qr_code']?.toString() ?? '';
    final ticketId = ticket['id']?.toString() ?? '';
    final ticketNumber = ticket['ticket_number']?.toString() ?? ticketId;
    final status = ticket['status']?.toString() ?? 'active';
    final isUsed = status == 'used';

    final dateStr = event['start_time'];
    DateTime dt;
    try { dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now(); } catch (_) { dt = DateTime.now(); }
    final dateDisplay = '${dt.day}/${dt.month}/${dt.year}';

    final isConfirmed = status == 'confirmed' || status == 'valid' || (isUpcoming && !isUsed);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event))),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isConfirmed 
              ? [const Color(0xFF2C3544), const Color(0xFF0F141E)] 
              : [const Color(0xFF1A1F26), const Color(0xFF0A0C10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (isUsed ? language.translate('attended') : (isUpcoming ? language.translate('active') : language.translate('expired'))).toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(width: 6),
                                Container(width: 1, height: 10, color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(width: 6),
                                Text(
                                  '#$ticketNumber',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Date: $dateDisplay', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => QRCodeScreen(
                                  qrCode: qrCode,
                                  eventTitle: title,
                                  ticketId: ticketId,
                                  ticketNumber: ticketNumber,
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
                              minimumSize: const Size(0, 34),
                            ),
                            child: Text(isUsed ? language.translate('view_details') : language.translate('view_tickets'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // QR Code Placeholder
                    Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                      ),
                      child: Icon(Icons.qr_code_2_rounded, size: 64, color: isUsed ? Colors.grey : Colors.black),
                    ),
                  ],
                ),
              ),
              // Perforation effect
              Positioned(
                right: 110,
                top: -10,
                bottom: -10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(10, (index) => Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(color: AppColors.bgDark, shape: BoxShape.circle),
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
