import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../utils/constants.dart';

class AssistantEventWorkScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const AssistantEventWorkScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<AssistantEventWorkScreen> createState() => _AssistantEventWorkScreenState();
}

class _AssistantEventWorkScreenState extends State<AssistantEventWorkScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AssistantProvider>(context, listen: false);
    final data = await provider.fetchEventWorkDetails(widget.eventId);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  void _openScanner() {
    final language = Provider.of<LanguageProvider>(context, listen: false);
    final timeStatus = _data?['event']?['time_status'] ?? 'upcoming';
    if (timeStatus != 'live') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${language.translate('cannot_scan_msg')} $timeStatus. ${language.translate('scanning_allowed_msg')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QRScannerPage(
          eventId: widget.eventId,
          eventTitle: widget.eventTitle,
          onScanComplete: () => _loadData(),
        ),
      ),
    );
  }

  List<dynamic> get _filteredParticipants {
    final participants = (_data?['participants'] as List<dynamic>?) ?? [];
    if (_searchQuery.isEmpty) return participants;
    final q = _searchQuery.toLowerCase();
    return participants.where((p) {
      final name = (p['user_name'] ?? '').toString().toLowerCase();
      final qr = (p['qr_code'] ?? '').toString().toLowerCase();
      return name.contains(q) || qr.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    final stats = _data?['stats'] ?? {};
    final totalTickets = stats['total_tickets'] ?? 0;
    final scannedToday = stats['scanned_today'] ?? 0;
    final myScansToday = stats['my_scans_today'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.eventTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Scan QR Button ──
                    (() {
                      final timeStatus = _data?['event']?['time_status'] ?? 'upcoming';
                      final isLive = timeStatus == 'live';
                      return GestureDetector(
                        onTap: _openScanner,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: isLive
                                ? AppColors.accentGradient
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade900,
                                      Colors.grey.shade800,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(20),
                            border: isLive ? null : Border.all(color: Colors.white10),
                            boxShadow: [
                              if (isLive)
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isLive ? Icons.qr_code_scanner_rounded : Icons.lock_outline_rounded,
                                size: 40,
                                color: isLive ? Colors.white : Colors.white60,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isLive ? language.translate('scan_qr_code') : language.translate('scanning_locked'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isLive ? Colors.white : Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLive
                                    ? language.translate('tap_to_open_camera')
                                    : language.translate('scanning_starts_when_live'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLive ? Colors.white70 : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })(),
                    const SizedBox(height: 20),

                    // ── Stats Cards ──
                    Row(
                       children: [
                         _statCard(language.translate('total'), totalTickets.toString(), Icons.confirmation_number_outlined, AppColors.accent),
                         const SizedBox(width: 12),
                         _statCard(language.translate('scanned_today'), scannedToday.toString(), Icons.check_circle_outline, AppColors.success),
                         const SizedBox(width: 12),
                         _statCard(language.translate('my_scans'), myScansToday.toString(), Icons.person_outline, AppColors.accent2),
                       ],
                     ),
                    const SizedBox(height: 24),

                    // ── Search ──
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                           hintText: language.translate('search_name_qr'),
                           hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4)),
                           prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                           border: InputBorder.none,
                           contentPadding: const EdgeInsets.symmetric(vertical: 14),
                         ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Participants Header ──
                    Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(language.translate('registered_attendees'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent2)),
                         Text('${_filteredParticipants.length} ${language.translate('found')}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                       ],
                     ),
                    const SizedBox(height: 12),

                    // ── Participants List ──
                    if (_filteredParticipants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                           child: Text(language.translate('no_participants_found'), style: const TextStyle(color: AppColors.textMuted)),
                         ),
                      )
                    else
                      ..._filteredParticipants.map((p) => _buildParticipantCard(p, language)),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> p, LanguageProvider language) {
    final name = p['user_name'] ?? 'Unknown';
    final qrCode = p['qr_code'] ?? '';
    final status = p['ticket_status'] ?? 'valid';
    final scannedToday = p['scanned_today'] ?? false;
    final totalDaysAttended = p['total_days_attended'] ?? 0;
    final scannedBy = p['scanned_by'];
    final scannedAt = p['scanned_at'];

    String timeStr = '';
    if (scannedAt != null) {
      timeStr = formatTo12Hour(scannedAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scannedToday ? AppColors.textMuted.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scannedToday
                  ? AppColors.textMuted.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
            ),
            child: Icon(
              scannedToday ? Icons.check_circle : Icons.qr_code_2_rounded,
              size: 20,
              color: scannedToday ? AppColors.textMuted : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scannedToday ? AppColors.textMuted : Colors.white,
                )),
                const SizedBox(height: 2),
                Text(
                  qrCode.length > 20 ? '${qrCode.substring(0, 20)}...' : qrCode,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.6), fontFamily: 'monospace'),
                ),
                if (totalDaysAttended > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 12, color: AppColors.accent2),
                      const SizedBox(width: 4),
                      Text(
                        '${language.translate('days_attended')}: $totalDaysAttended',
                        style: const TextStyle(fontSize: 11, color: AppColors.accent2, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
                if (scannedToday && scannedBy != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 12, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text('$scannedBy', style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.5))),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 12, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(timeStr, style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.5))),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scannedToday
                  ? AppColors.textMuted.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
               scannedToday ? language.translate('scanned') : language.translate('valid'),
               style: TextStyle(
                 fontSize: 11,
                 fontWeight: FontWeight.w600,
                 color: scannedToday ? AppColors.textMuted : AppColors.success,
               ),
             ),
          ),
        ],
      ),
    );
  }
}

// ── Manual Entry Page ────────────────────────────────────────────────────────

class _ManualEntryPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final VoidCallback onScanComplete;

  const _ManualEntryPage({
    required this.eventId,
    required this.eventTitle,
    required this.onScanComplete,
  });

  @override
  State<_ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<_ManualEntryPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _processCode(String code) async {
    setState(() => _isProcessing = true);

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final result = await ticketProvider.processCheckIn(code, eventId: widget.eventId);

    if (!mounted) return;

    final success = result['success'] == true;
    final message = result['message'] ?? 'Unknown result';

    // Show result dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (success ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.error,
                size: 48,
                color: success ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success
                  ? Provider.of<LanguageProvider>(ctx, listen: false).translate('checkin_successful')
                  : Provider.of<LanguageProvider>(ctx, listen: false).translate('checkin_failed'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: success ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isProcessing = false);
                _textController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                Provider.of<LanguageProvider>(ctx, listen: false).translate('scan_next'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    widget.onScanComplete();
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.eventTitle, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined, color: AppColors.accent, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        language.translate('manual_entry'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    language.translate('enter_ticket_code_hint'),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      autofocus: true,
                      enabled: !_isProcessing,
                      decoration: InputDecoration(
                        hintText: language.translate('ticket_code_placeholder'),
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
            else
              ElevatedButton(
                onPressed: () {
                  final code = _textController.text.trim();
                  if (code.isNotEmpty) {
                    _processCode(code);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  language.translate('check_in'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _QRScannerPage(
                      eventId: widget.eventId,
                      eventTitle: widget.eventTitle,
                      onScanComplete: widget.onScanComplete,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(
                language.translate('switch_to_camera'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Embedded QR Scanner Page ──────────────────────────────────────────────────

class _QRScannerPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final VoidCallback onScanComplete;

  const _QRScannerPage({required this.eventId, required this.eventTitle, required this.onScanComplete});

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  IconData? _lastIcon;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _controller?.stop();
    _processCode(code);
  }

  void _processCode(String code) async {
    setState(() => _isProcessing = true);
    _controller?.stop();

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final result = await ticketProvider.processCheckIn(code, eventId: widget.eventId);

    if (!mounted) return;

    final success = result['success'] == true;
    final message = result['message'] ?? 'Unknown result';

    setState(() {
      _lastIcon = success ? Icons.check_circle : Icons.error;
    });

    // Show result dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (success ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
              ),
              child: Icon(_lastIcon, size: 48, color: success ? AppColors.success : AppColors.danger),
            ),
            const SizedBox(height: 16),
             Text(
               success ? Provider.of<LanguageProvider>(ctx, listen: false).translate('checkin_successful') : Provider.of<LanguageProvider>(ctx, listen: false).translate('checkin_failed'),
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: success ? AppColors.success : AppColors.danger),
             ),
             const SizedBox(height: 8),
             Text(message, style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
           ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isProcessing = false);
                _controller?.start();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(Provider.of<LanguageProvider>(ctx, listen: false).translate('scan_next'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _controller?.start();
      }
    });

    widget.onScanComplete();
  }

  void _navigateToManualEntry() {
    _controller?.dispose();
    _controller = null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _ManualEntryPage(
          eventId: widget.eventId,
          eventTitle: widget.eventTitle,
          onScanComplete: widget.onScanComplete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
         backgroundColor: Colors.black,
         title: Text(widget.eventTitle, style: const TextStyle(fontSize: 16)),
         centerTitle: true,
       ),
       body: Consumer<LanguageProvider>(
         builder: (context, language, child) {
           return Stack(
             children: [
               // Camera
               MobileScanner(
                 controller: _controller,
                 onDetect: _handleScan,
               ),
 
               // Overlay
               Center(
                 child: Container(
                   width: 260,
                   height: 260,
                   decoration: BoxDecoration(
                     border: Border.all(color: AppColors.accent, width: 2),
                     borderRadius: BorderRadius.circular(20),
                   ),
                 ),
               ),
 
               // Bottom instruction
               Positioned(
                 bottom: 40,
                 left: 0,
                 right: 0,
                 child: Column(
                   children: [
                     if (_isProcessing)
                       const CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)
                     else ...[
                       Container(
                         margin: const EdgeInsets.symmetric(horizontal: 40),
                         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                         decoration: BoxDecoration(
                           color: Colors.black.withValues(alpha: 0.7),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(
                           language.translate('point_camera_ticket'),
                           style: const TextStyle(color: Colors.white70, fontSize: 14),
                           textAlign: TextAlign.center,
                         ),
                       ),
                       const SizedBox(height: 16),
                       GestureDetector(
                         onTap: _navigateToManualEntry,
                         child: Container(
                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                           decoration: BoxDecoration(
                             color: AppColors.accent.withValues(alpha: 0.85),
                             borderRadius: BorderRadius.circular(30),
                             boxShadow: [
                               BoxShadow(
                                 color: AppColors.accent.withValues(alpha: 0.4),
                                 blurRadius: 8,
                                 offset: const Offset(0, 3),
                               ),
                             ],
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                               const SizedBox(width: 8),
                               Text(
                                 language.translate('manual_entry'),
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 14,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                     ],
                   ],
                 ),
               ),
             ],
           );
         },
       ),
     );
  }
}
