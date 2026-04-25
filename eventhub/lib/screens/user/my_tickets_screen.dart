import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../utils/constants.dart';
import 'qr_code_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});
  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchMyTickets();
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
                  const Expanded(child: Text('My Tickets', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
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
            // ── Tab Bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: TabBar(
                controller: _tabCtrl,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  gradient: AppColors.accentGradientH,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(text: 'Upcoming (${ticketProv.upcomingTickets.length})'),
                  Tab(text: 'History (${ticketProv.pastTickets.length})'),
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
                        _buildTicketList(ticketProv.upcomingTickets, isUpcoming: true),
                        _buildTicketList(ticketProv.pastTickets, isUpcoming: false),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<dynamic> tickets, {required bool isUpcoming}) {
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
            isUpcoming ? 'No upcoming tickets' : 'No past events',
            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 15),
          ),
          if (isUpcoming) ...[
            const SizedBox(height: 8),
            Text('Book a ticket from Explore tab', style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4), fontSize: 13)),
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
    final event = ticket['event'] as Map<String, dynamic>? ?? {};
    final title = event['title']?.toString() ?? 'Unknown Event';
    final venueName = event['venue']?['name']?.toString() ?? event['location']?.toString() ?? 'TBA';
    final qrCode = ticket['qr_code']?.toString() ?? '';
    final ticketId = ticket['id']?.toString() ?? '';
    final status = ticket['status']?.toString() ?? 'active';
    final isUsed = status == 'used';

    final dateStr = event['start_time'];
    DateTime dt;
    try { dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now(); } catch (_) { dt = DateTime.now(); }
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final statusColor = isUsed ? AppColors.success : (isUpcoming ? AppColors.accent2 : AppColors.textMuted);
    final statusText = isUsed ? 'ATTENDED' : (isUpcoming ? 'ACTIVE' : 'EXPIRED');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ── Colored Top Bar ──
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [statusColor, statusColor.withValues(alpha: 0.3)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title + Status ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Dashed Divider ──
                Row(children: List.generate(40, (i) => Expanded(
                  child: Container(margin: EdgeInsets.only(right: i < 39 ? 3 : 0), height: 1, color: AppColors.border),
                ))),
                const SizedBox(height: 14),
                // ── Info Row ──
                Row(
                  children: [
                    // Date block
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [statusColor.withValues(alpha: 0.12), statusColor.withValues(alpha: 0.04)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        Text(dt.day.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: statusColor, height: 1)),
                        Text(months[dt.month - 1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      ]),
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
                            const SizedBox(width: 5),
                            Text(timeStr, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
                            const SizedBox(width: 5),
                            Expanded(child: Text(venueName, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.textMuted.withValues(alpha: 0.6)),
                            const SizedBox(width: 5),
                            Text('Ticket #$ticketId', style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                          ]),
                        ],
                      ),
                    ),
                    // QR Button
                    if (qrCode.isNotEmpty)
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRCodeScreen(
                          qrCode: qrCode,
                          eventTitle: title,
                          ticketId: ticketId,
                          isUsed: isUsed,
                        ))),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: isUpcoming
                                ? const LinearGradient(colors: [AppColors.accent, Color(0xFF8B5CF6)])
                                : null,
                            color: isUpcoming ? null : AppColors.bgCard2,
                            borderRadius: BorderRadius.circular(14),
                            border: isUpcoming ? null : Border.all(color: AppColors.border),
                            boxShadow: isUpcoming ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                          ),
                          child: Icon(Icons.qr_code_2_rounded, size: 28, color: isUpcoming ? Colors.white : AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
