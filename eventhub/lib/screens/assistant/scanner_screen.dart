import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'event_participants_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  // Manual entry custom overlay state
  bool _showManualInput = false;
  final TextEditingController _manualCodeController = TextEditingController();
  Map<String, dynamic>? _manualResult;
  bool _isManualSubmitting = false;

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
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

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
      title = Provider.of<LanguageProvider>(context, listen: false).translate('entry_allowed');
    } else if (statusCode == 422) {
      // Already used
      icon = Icons.warning_amber;
      color = AppColors.warning;
      title = Provider.of<LanguageProvider>(context, listen: false).translate('already_entered');
    } else if (statusCode == 404) {
      // Invalid QR
      icon = Icons.cancel;
      color = AppColors.danger;
      title = Provider.of<LanguageProvider>(context, listen: false).translate('invalid_ticket');
    } else if (statusCode == 403) {
      // Unauthorized event
      icon = Icons.block;
      color = AppColors.danger;
      title = Provider.of<LanguageProvider>(context, listen: false).translate('not_your_event');
    } else {
      icon = Icons.error;
      color = AppColors.danger;
      title = Provider.of<LanguageProvider>(context, listen: false).translate('error');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
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
                Navigator.pop(dialogCtx);
                // Cooldown to prevent immediate double scan
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    _controller.start();
                  }
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                 Provider.of<LanguageProvider>(dialogCtx, listen: false).translate('scan_next'),
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
    final language = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
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
                         Text(
                           language.translate('scanner'),
                           style: const TextStyle(
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
                  // Participants List
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventParticipantsScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.people_alt, color: Colors.white, size: 20),
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
          // Bottom instruction + manual entry button
          Positioned(
            bottom: 40,
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
                         _isProcessing ? language.translate('processing') : language.translate('point_camera_ticket'),
                         style: TextStyle(
                           color: Colors.white.withValues(alpha: 0.9),
                           fontWeight: FontWeight.w500,
                           fontSize: 14,
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Manual entry button
                GestureDetector(
                  onTap: _isProcessing ? null : () => _showManualEntrySheet(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_alt_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          language.translate('manual_entry'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
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
          // Inline Manual Input Overlay
          if (_showManualInput)
            _buildManualInputOverlay(language),
        ],
      ),
    );
  }

  void _showManualEntrySheet() {
    _controller.stop();
    setState(() {
      _showManualInput = true;
      _manualResult = null;
      _isManualSubmitting = false;
      _manualCodeController.clear();
    });
  }

  Widget _buildManualInputOverlay(LanguageProvider language) {
    IconData? icon;
    Color? resultColor;
    String? title;
    String? message;

    if (_manualResult != null) {
      final bool success = _manualResult!['success'] == true;
      message = _manualResult!['message'] ?? 'Unknown result';
      final int statusCode = _manualResult!['statusCode'] ?? 0;

      if (success) {
        icon = Icons.check_circle;
        resultColor = AppColors.success;
        title = language.translate('entry_allowed');
      } else if (statusCode == 422) {
        icon = Icons.warning_amber;
        resultColor = AppColors.warning;
        title = language.translate('already_entered');
      } else if (statusCode == 404) {
        icon = Icons.cancel;
        resultColor = AppColors.danger;
        title = language.translate('invalid_ticket');
      } else if (statusCode == 403) {
        icon = Icons.block;
        resultColor = AppColors.danger;
        title = language.translate('not_your_event');
      } else {
        icon = Icons.error;
        resultColor = AppColors.danger;
        title = language.translate('error');
      }
    }

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black.withValues(alpha: 0.82),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        language.translate('manual_entry'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (_manualResult == null && !_isManualSubmitting)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 24),
                          onPressed: () {
                            setState(() {
                              _showManualInput = false;
                            });
                            _controller.start();
                          },
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (_manualResult == null) ...[
                    // Input Mode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.keyboard_alt_outlined, color: AppColors.accent2, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              language.translate('enter_ticket_code_hint'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _manualCodeController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                      enabled: !_isManualSubmitting,
                      decoration: InputDecoration(
                        hintText: language.translate('ticket_code_placeholder'),
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.confirmation_number_outlined, color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isManualSubmitting
                            ? null
                            : () async {
                                final code = _manualCodeController.text.trim();
                                if (code.isEmpty) return;

                                setState(() {
                                  _isManualSubmitting = true;
                                });

                                final provider = Provider.of<TicketProvider>(context, listen: false);
                                final result = await provider.processCheckIn(code);

                                if (!mounted) return;

                                setState(() {
                                  _isManualSubmitting = false;
                                  _manualResult = result;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isManualSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    language.translate('check_in'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ] else ...[
                    // Result Mode
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: resultColor!.withValues(alpha: 0.15),
                        border: Border.all(color: resultColor.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Icon(icon, color: resultColor, size: 44),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _manualResult = null;
                            _manualCodeController.clear();
                          });
                          // Cooldown before restarting camera
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              setState(() {
                                _showManualInput = false;
                              });
                              _controller.start();
                            }
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: resultColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          language.translate('scan_next'),
                          style: TextStyle(
                            color: resultColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         title: Text(Provider.of<LanguageProvider>(dialogCtx, listen: false).translate('logout'), style: const TextStyle(fontWeight: FontWeight.w700)),
         content: Text(Provider.of<LanguageProvider>(dialogCtx, listen: false).translate('confirm_logout'), style: const TextStyle(color: AppColors.textMuted)),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(dialogCtx),
             child: Text(Provider.of<LanguageProvider>(dialogCtx, listen: false).translate('cancel'), style: const TextStyle(color: AppColors.textMuted)),
           ),
           TextButton(
             onPressed: () async {
               Navigator.pop(dialogCtx);
               await auth.logout();
               if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(builder: (_) => const LoginScreen()),
                   (route) => false,
                 );
               }
             },
             child: Text(Provider.of<LanguageProvider>(dialogCtx, listen: false).translate('logout'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
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
