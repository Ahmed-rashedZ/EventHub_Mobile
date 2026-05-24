import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class EventParticipantsScreen extends StatefulWidget {
  const EventParticipantsScreen({super.key});

  @override
  State<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  bool _isLoading = true;
  List<dynamic> _participants = [];
  List<dynamic> _filteredParticipants = [];
  String _searchQuery = '';
  int _attendedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final eventId = auth.user?['event_id'];

    if (eventId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final provider = Provider.of<TicketProvider>(context, listen: false);
    final data = await provider.fetchEventParticipants(eventId);

    if (mounted) {
      setState(() {
        _participants = data;
        _filteredParticipants = data;
        _totalCount = data.length;
        _attendedCount = data.where((t) => t['scanned_today'] == true).length;
        _isLoading = false;
      });
    }
  }

  void _filterParticipants(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredParticipants = _participants;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredParticipants = _participants.where((t) {
          final userName = (t['user']?['name'] ?? '').toString().toLowerCase();
          final ticketCode = (t['qr_code'] ?? '').toString().toLowerCase();
          return userName.contains(lowerQuery) || ticketCode.contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final eventId = auth.user?['event_id'];

    if (eventId == null) {
       return Scaffold(
         backgroundColor: AppColors.bgDark,
         appBar: AppBar(title: Text(Provider.of<LanguageProvider>(context, listen: false).translate('participants'))),
         body: Center(
           child: Text(
             Provider.of<LanguageProvider>(context, listen: false).translate('not_assigned_event'),
             style: const TextStyle(color: AppColors.textMuted),
           ),
         ),
       );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
         elevation: 0,
         iconTheme: const IconThemeData(color: Colors.white),
         title: Text(Provider.of<LanguageProvider>(context, listen: false).translate('event_participants'), style: const TextStyle(color: Colors.white)),
       ),
       body: _isLoading
           ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
           : Column(
               children: [
                 _buildStatsCard(context),
                 Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                       hintText: Provider.of<LanguageProvider>(context, listen: false).translate('search_name_qr'),
                       hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
                       prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                       filled: true,
                       fillColor: AppColors.bgCard,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12),
                         borderSide: BorderSide.none,
                       ),
                     ),
                    onChanged: _filterParticipants,
                  ),
                ),
                Expanded(
                  child: _filteredParticipants.isEmpty
                       ? Center(
                           child: Text(
                             Provider.of<LanguageProvider>(context, listen: false).translate('no_participants_found'),
                             style: const TextStyle(color: AppColors.textMuted),
                           ),
                         )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredParticipants.length,
                          itemBuilder: (context, index) {
                            final ticket = _filteredParticipants[index];
                            return _buildParticipantCard(ticket);
                          },
                        ),
                ),
              ],
            ),
    );
  }

   Widget _buildStatsCard(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context, listen: false);
    return Container(
      width: double.infinity,
      color: AppColors.bgCard,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(language.translate('total'), _totalCount, AppColors.accent),
          _buildStatItem(language.translate('attended'), _attendedCount, AppColors.success),
          _buildStatItem(language.translate('pending'), _totalCount - _attendedCount, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(dynamic ticket) {
    final user = ticket['user'];
    final userName = user?['name'] ?? 'Unknown User';
    final email = user?['email'] ?? '';
    final avatar = user?['avatar'] ?? user?['image'];
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    final scannedToday = ticket['scanned_today'] ?? false;
    final totalDaysAttended = ticket['total_days_attended'] ?? 0;
    final qrCode = ticket['qr_code'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            backgroundImage: avatar != null ? NetworkImage('${ApiConstants.imageUrl}$avatar') : null,
            child: avatar == null ? Text(initial, style: const TextStyle(color: AppColors.accent)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                 Text(
                   '${Provider.of<LanguageProvider>(context, listen: false).translate('code_label')} $qrCode',
                   style: const TextStyle(color: AppColors.accent2, fontSize: 12),
                 ),
                if (totalDaysAttended > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 12, color: AppColors.accent2),
                      const SizedBox(width: 4),
                      Text(
                        '${Provider.of<LanguageProvider>(context, listen: false).translate('days_attended')}: $totalDaysAttended',
                        style: const TextStyle(color: AppColors.accent2, fontSize: 12),
                      ),
                    ],
                  ),
                ],
               ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scannedToday ? AppColors.success.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
             child: Text(
               scannedToday ? Provider.of<LanguageProvider>(context, listen: false).translate('attended') : Provider.of<LanguageProvider>(context, listen: false).translate('pending'),
               style: TextStyle(
                 color: scannedToday ? AppColors.success : AppColors.warning,
                 fontWeight: FontWeight.bold,
                 fontSize: 12,
               ),
             ),
          ),
        ],
      ),
    );
  }
}
