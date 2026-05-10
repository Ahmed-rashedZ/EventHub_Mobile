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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(children: [
                    Text(months[dt.month - 1].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent2)),
                    const SizedBox(height: 2),
                    Text(dt.day.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                  ]),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.8)),
                        const SizedBox(width: 5),
                        Text(timeStr, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted.withValues(alpha: 0.8)),
                        const SizedBox(width: 5),
                        Expanded(child: Text(venueName, style: TextStyle(fontSize: 13, color: AppColors.textMuted.withValues(alpha: 0.9), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Ticket Divider with cutouts
          Row(
            children: [
              Container(width: 10, height: 20, decoration: const BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.horizontal(right: Radius.circular(20)))),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boxWidth = constraints.constrainWidth();
                    const dashWidth = 6.0;
                    final dashCount = (boxWidth / (2 * dashWidth)).floor();
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(dashCount, (_) => Container(width: dashWidth, height: 1.5, color: AppColors.borderLight)),
                    );
                  },
                ),
              ),
              Container(width: 10, height: 20, decoration: const BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.horizontal(left: Radius.circular(20)))),
            ],
          ),

          // Bottom Action Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 12),
                Text('#$ticketId', style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (qrCode.isNotEmpty && !isUsed)
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRCodeScreen(qrCode: qrCode, eventTitle: title, ticketId: ticketId, isUsed: isUsed))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text('View QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
