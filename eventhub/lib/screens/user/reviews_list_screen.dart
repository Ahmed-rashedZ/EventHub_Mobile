import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/event_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/rate_event_bottom_sheet.dart';

class ReviewsListScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const ReviewsListScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  bool _isLoading = true;
  double _averageRating = 0.0;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final data = await eventProvider.fetchReviews(widget.eventId);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data != null) {
          _averageRating = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
          _reviews = data['reviews'] ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(language.translate('reviews'), style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _reviews.isEmpty
              ? Center(
                  child: Text(
                    language.translate('no_reviews_msg'),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                )
              : Column(
                  children: [
                    _buildSummaryCard(language),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return _buildReviewItem(review);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard(LanguageProvider language) {
    return Container(
      width: double.infinity,
      color: AppColors.bgCard,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            _averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < _averageRating.round() ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 24,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '${language.translate('based_on')} ${_reviews.length} ${language.translate('reviews')}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(dynamic review) {
    final user = review['user'];
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = review['review_text'] as String?;
    final dateStr = review['updated_at'] ?? review['created_at'];
    
    String formattedDate = '';
    if (dateStr != null) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormat.yMMMd().format(date);
      } catch (_) {}
    }

    final userName = user?['name'] ?? 'Unknown User';
    final avatar = user?['avatar'] ?? user?['image'];
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return GestureDetector(
      onLongPress: () => _showReviewOptions(review),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                backgroundImage: avatar != null ? NetworkImage('${ApiConstants.imageUrl}$avatar') : null,
                child: avatar == null ? Text(initial, style: const TextStyle(color: AppColors.accent)) : null,
              ),
              const SizedBox(width: 12),
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
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: AppColors.warning,
                            size: 14,
                          );
                        }),
                        const SizedBox(width: 8),
                        if (formattedDate.isNotEmpty)
                          Text(
                            formattedDate,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (text != null && text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(color: Colors.white, height: 1.5),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _showReviewOptions(dynamic review) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final language = Provider.of<LanguageProvider>(context, listen: false);
    
    // Only allow edit/delete if it's the current user's review
    if (auth.user?['id'] != review['user_id']) return;

    final date = review['created_at'];
    String fullDateStr = '';
    if (date != null) {
      final dt = DateTime.tryParse(date);
      if (dt != null) {
        fullDateStr = DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            if (fullDateStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(fullDateStr, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: Text(language.translate('edit'), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _editReview(review);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.danger),
              title: Text(language.translate('delete'), style: const TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteReview(review);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _editReview(dynamic review) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RateEventBottomSheet(
        eventId: widget.eventId,
        eventTitle: widget.eventTitle,
        initialRating: review['rating'] ?? 0,
        initialReview: review['review_text'] ?? '',
      ),
    );
    if (result == true) {
      _fetchReviews();
    }
  }

  void _deleteReview(dynamic review) async {
    final language = Provider.of<LanguageProvider>(context, listen: false);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(language.translate('delete') ?? 'Delete', style: const TextStyle(color: Colors.white)),
        content: Text(language.translate('confirm_delete_msg') ?? 'Are you sure you want to delete your review?', style: const TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(language.translate('cancel') ?? 'Cancel', style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(language.translate('delete') ?? 'Delete', style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = Provider.of<EventProvider>(context, listen: false);
    final error = await provider.deleteReview(widget.eventId);
    
    if (!mounted) return;

    if (error == null) {
      _fetchReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    }
  }
}
