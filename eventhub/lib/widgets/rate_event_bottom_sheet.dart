import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/event_provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'gradient_button.dart';

class RateEventBottomSheet extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final int initialRating;
  final String? initialReview;

  const RateEventBottomSheet({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.initialRating = 0,
    this.initialReview,
  });

  @override
  State<RateEventBottomSheet> createState() => _RateEventBottomSheetState();
}

class _RateEventBottomSheetState extends State<RateEventBottomSheet> {
  late int _selectedRating;
  late final TextEditingController _reviewCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
    _reviewCtrl = TextEditingController(text: widget.initialReview);
  }
  String? _statusMessage;
  bool _isSuccess = false;

  void _submitRating() async {
    final language = Provider.of<LanguageProvider>(context, listen: false);
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language.translate('select_star_rating')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final error = await eventProvider.rateEvent(
      widget.eventId,
      _selectedRating,
      reviewText: _reviewCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() {
        _statusMessage = error;
        _isSuccess = false;
      });
    } else {
      setState(() {
        _statusMessage = language.translate('rating_success');
        _isSuccess = true;
      });
      // Give user time to see success message
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            language.translate('rate_event'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.eventTitle,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRating = starIndex);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _reviewCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: language.translate('write_review'),
              hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5)),
              filled: true,
              fillColor: AppColors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (_isSuccess ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (_isSuccess ? AppColors.success : AppColors.danger).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _isSuccess ? AppColors.success : AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isSuccess ? AppColors.success : AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          GradientButton(
            text: language.translate('submit_rating'),
            isLoading: _isLoading,
            onPressed: _submitRating,
            icon: Icons.send,
          ),
        ],
      ),
    );
  }
}
