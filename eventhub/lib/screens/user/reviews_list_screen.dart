import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/event_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/constants.dart';

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

    return Container(
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
    );
  }
}
