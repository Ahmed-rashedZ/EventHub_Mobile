import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/constants.dart';

class QRCodeScreen extends StatelessWidget {
  final String qrCode;
  final String eventTitle;
  final String ticketId;
  final bool isUsed;

  const QRCodeScreen({
    super.key,
    required this.qrCode,
    required this.eventTitle,
    required this.ticketId,
    this.isUsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Access Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Ticket card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top colored strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent, Color(0xFF8B5CF6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.confirmation_number, color: Colors.white, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            eventTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dotted line separator
                    Row(
                      children: List.generate(
                        30,
                        (i) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 2,
                            color: i.isEven ? Colors.grey.shade300 : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // QR Code
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Text(
                            'Scan at the entrance',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // The QR code uses the actual qr_code string from the backend
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: qrCode,
                              version: QrVersions.auto,
                              size: 220.0,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1a1a2e),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1a1a2e),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isUsed 
                                  ? Colors.red.shade50 
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUsed 
                                    ? Colors.red.shade200 
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUsed ? Icons.check_circle : Icons.verified,
                                  size: 16,
                                  color: isUsed ? Colors.red.shade600 : Colors.green.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isUsed ? 'TICKET USED' : 'VALID TICKET',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isUsed ? Colors.red.shade600 : Colors.green.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Ticket ID
                          Text(
                            'TICKET #$ticketId',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            qrCode,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Info text
              Text(
                'Keep this QR code safe. You will need it to enter the event.',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
