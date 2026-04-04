import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);

    final provider = Provider.of<TicketProvider>(context, listen: false);
    // Send the raw QR code string directly to the backend
    final result = await provider.processCheckIn(rawValue);

    if (!mounted) return;

    _showResultDialog(result);
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final bool success = result['success'] == true;
    final String message = result['message'] ?? 'Unknown result';
    final int statusCode = result['statusCode'] ?? 0;

    // Determine icon and colors based on result
    IconData icon;
    Color color;
    String title;

    if (success) {
      icon = Icons.check_circle;
      color = AppColors.success;
      title = 'Entry Allowed ✅';
    } else if (statusCode == 422) {
      // Already used
      icon = Icons.warning_amber;
      color = AppColors.warning;
      title = 'Already Entered ⚠️';
    } else if (statusCode == 404) {
      // Invalid QR
      icon = Icons.cancel;
      color = AppColors.danger;
      title = 'Invalid Ticket ❌';
    } else if (statusCode == 403) {
      // Unauthorized event
      icon = Icons.block;
      color = AppColors.danger;
      title = 'Not Your Event 🚫';
    } else {
      icon = Icons.error;
      color = AppColors.danger;
      title = 'Error';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(icon, color: color, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Cooldown to prevent immediate double scan
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _isProcessing = false);
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Scan Next',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Scanning overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.accent,
                borderRadius: 20,
                borderLength: 40,
                borderWidth: 8,
                cutOutSize: 280,
              ),
            ),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('🎯', style: TextStyle(fontSize: 16))),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Scanner',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // User info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      auth.userName,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Logout
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, auth),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.logout, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isProcessing ? Icons.hourglass_top : Icons.qr_code_scanner,
                        color: _isProcessing ? AppColors.warning : AppColors.accent2,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isProcessing ? 'Processing...' : 'Point camera at ticket QR code',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent2),
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double overlayColorOpacity;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColorOpacity = 80,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final innerRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );
    final outerData = Path()..addRect(rect);
    final innerData = Path()
      ..addRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius)));
    return Path.combine(PathOperation.difference, outerData, innerData);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(overlayColorOpacity.toInt())
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final center = rect.center;
    final innerRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    var path = Path();

    // Top left
    path.moveTo(innerRect.left, innerRect.top + borderLength);
    path.lineTo(innerRect.left, innerRect.top + borderRadius);
    path.quadraticBezierTo(
        innerRect.left, innerRect.top, innerRect.left + borderRadius, innerRect.top);
    path.lineTo(innerRect.left + borderLength, innerRect.top);

    // Top right
    path.moveTo(innerRect.right - borderLength, innerRect.top);
    path.lineTo(innerRect.right - borderRadius, innerRect.top);
    path.quadraticBezierTo(
        innerRect.right, innerRect.top, innerRect.right, innerRect.top + borderRadius);
    path.lineTo(innerRect.right, innerRect.top + borderLength);

    // Bottom right
    path.moveTo(innerRect.right, innerRect.bottom - borderLength);
    path.lineTo(innerRect.right, innerRect.bottom - borderRadius);
    path.quadraticBezierTo(
        innerRect.right, innerRect.bottom, innerRect.right - borderRadius, innerRect.bottom);
    path.lineTo(innerRect.right - borderLength, innerRect.bottom);

    // Bottom left
    path.moveTo(innerRect.left + borderLength, innerRect.bottom);
    path.lineTo(innerRect.left + borderRadius, innerRect.bottom);
    path.quadraticBezierTo(
        innerRect.left, innerRect.bottom, innerRect.left, innerRect.bottom - borderRadius);
    path.lineTo(innerRect.left, innerRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColorOpacity: overlayColorOpacity,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
