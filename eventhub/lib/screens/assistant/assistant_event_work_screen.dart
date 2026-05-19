import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/assistant_provider.dart';
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
    final stats = _data?['stats'] ?? {};
    final totalTickets = stats['total_tickets'] ?? 0;
    final totalScanned = stats['total_scanned'] ?? 0;
    final myScans = stats['my_scans'] ?? 0;

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
                    GestureDetector(
                      onTap: _openScanner,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 40, color: Colors.white),
                            SizedBox(height: 8),
                            Text('Scan QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('Tap to open camera', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Stats Cards ──
                    Row(
                      children: [
                        _statCard('Total', totalTickets.toString(), Icons.confirmation_number_outlined, AppColors.accent),
                        const SizedBox(width: 12),
                        _statCard('Scanned', totalScanned.toString(), Icons.check_circle_outline, AppColors.success),
                        const SizedBox(width: 12),
                        _statCard('My Scans', myScans.toString(), Icons.person_outline, AppColors.accent2),
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
                          hintText: 'Search by name or QR code...',
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
                        const Text('Registered Attendees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accent2)),
                        Text('${_filteredParticipants.length} found', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                        child: const Center(
                          child: Text('No participants found', style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    else
                      ..._filteredParticipants.map((p) => _buildParticipantCard(p)),

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

  Widget _buildParticipantCard(Map<String, dynamic> p) {
    final name = p['user_name'] ?? 'Unknown';
    final qrCode = p['qr_code'] ?? '';
    final status = p['ticket_status'] ?? 'valid';
    final isUsed = status == 'used';
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
        border: Border.all(color: isUsed ? AppColors.textMuted.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUsed
                  ? AppColors.textMuted.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
            ),
            child: Icon(
              isUsed ? Icons.check_circle : Icons.qr_code_2_rounded,
              size: 20,
              color: isUsed ? AppColors.textMuted : AppColors.success,
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
                  color: isUsed ? AppColors.textMuted : Colors.white,
                )),
                const SizedBox(height: 2),
                Text(
                  qrCode.length > 20 ? '${qrCode.substring(0, 20)}...' : qrCode,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.6), fontFamily: 'monospace'),
                ),
                if (isUsed && scannedBy != null) ...[
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
              color: isUsed
                  ? AppColors.textMuted.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isUsed ? 'Scanned' : 'Valid',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUsed ? AppColors.textMuted : AppColors.success,
              ),
            ),
          ),
        ],
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
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

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
              success ? 'Check-in Successful!' : 'Check-in Failed',
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Scan Next', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });

    widget.onScanComplete();
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
      body: Stack(
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
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Point camera at QR code on ticket',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
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
