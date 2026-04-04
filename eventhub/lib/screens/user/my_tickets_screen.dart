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
    final provider = Provider.of<TicketProvider>(context);

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
                  const Expanded(
                    child: Text(
                      'My Tickets',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => provider.fetchMyTickets(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.refresh, size: 20, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  gradient: AppColors.accentGradientH,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: [
                  Tab(text: 'Upcoming (${provider.upcomingTickets.length})'),
                  Tab(text: 'History (${provider.pastTickets.length})'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Error/debug info
            if (provider.myTickets.isEmpty && !provider.isLoadingTickets)
              const SizedBox.shrink(),
            // Tab Content
            Expanded(
              child: provider.isLoadingTickets
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.accent),
                          SizedBox(height: 12),
                          Text('Loading tickets...', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildTicketList(provider.upcomingTickets, isUpcoming: true, allTickets: provider.myTickets),
                        _buildTicketList(provider.pastTickets, isUpcoming: false, allTickets: provider.myTickets),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<dynamic> tickets, {required bool isUpcoming, required List<dynamic> allTickets}) {
    // If both tabs are empty but total tickets exist, show all tickets in the upcoming tab
    if (tickets.isEmpty && isUpcoming && allTickets.isNotEmpty) {
      // This handles cases where start_time may be null or in unexpected format
      return RefreshIndicator(
        onRefresh: () => Provider.of<TicketProvider>(context, listen: false).fetchMyTickets(),
        color: AppColors.accent,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: allTickets.length,
          itemBuilder: (context, i) {
            final ticket = allTickets[i] is Map<String, dynamic>
                ? allTickets[i] as Map<String, dynamic>
                : Map<String, dynamic>.from(allTickets[i]);
            return _buildTicketCard(context, ticket);
          },
        ),
      );
    }

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUpcoming ? Icons.confirmation_number_outlined : Icons.history,
              size: 64,
              color: AppColors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming tickets' : 'No ticket history',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              isUpcoming ? 'Book an event to get started!' : 'Your attended events will appear here',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<TicketProvider>(context, listen: false).fetchMyTickets(),
      color: AppColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tickets.length,
        itemBuilder: (context, i) {
          final ticket = tickets[i] is Map<String, dynamic>
              ? tickets[i] as Map<String, dynamic>
              : Map<String, dynamic>.from(tickets[i]);
          return _buildTicketCard(context, ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> ticket) {
    final event = ticket['event'] ?? {};
    final bool isUsed = ticket['status'] == 'used';
    final String statusText = isUsed ? 'USED' : 'ACTIVE';
    final Color statusColor = isUsed ? AppColors.danger : AppColors.success;
    final String qrCode = ticket['qr_code']?.toString() ?? '';

    final dateStr = event['start_time'];
    DateTime dt;
    try {
      dt = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      dt = DateTime.now();
    }
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with event name & status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bgSidebar.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event['title']?.toString() ?? 'Event',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ticket body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dt.day.toString(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent),
                      ),
                      Text(
                        months[dt.month - 1],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event['venue']?['name']?.toString() ?? 'TBA',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ticket #${ticket['id']}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // QR Button
                if (qrCode.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QRCodeScreen(
                            qrCode: qrCode,
                            eventTitle: event['title']?.toString() ?? 'Event',
                            ticketId: ticket['id'].toString(),
                            isUsed: isUsed,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_2, color: Colors.white, size: 24),
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
