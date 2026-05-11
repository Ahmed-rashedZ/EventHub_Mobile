import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'event_details_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final int userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<dynamic> _portfolio = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final profileRes = await _api.get('/profile/${widget.userId}');
      if (profileRes.statusCode == 200) {
        final profileData = profileRes.body.isNotEmpty ? (await _api.get('/profile/${widget.userId}')).body : null;
        if (profileData != null) {
          _profile = jsonDecode(profileData);
        }
      } else {
        _errorMessage = 'Failed to load profile';
      }

      final portfolioRes = await _api.get('/profile/${widget.userId}/portfolio');
      if (portfolioRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(portfolioRes.body);
        _portfolio = data['events'] ?? [];
      }
    } catch (e) {
      _errorMessage = 'Connection error.';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text(
            _errorMessage ?? 'Profile not found',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final user = _profile!['user'];
    final profile = user['profile'];
    final role = user['role'] ?? 'User';
    final name = profile != null && profile['company_name'] != null ? profile['company_name'] : user['name'];
    final bio = profile != null && profile['bio'] != null ? profile['bio'] : (user['bio'] ?? 'No bio available.');
    final logo = profile != null && profile['logo'] != null ? profile['logo'] : (user['avatar'] ?? user['image']);
    final joinedDate = user['created_at'] != null 
        ? DateFormat.yMMMd().format(DateTime.parse(user['created_at']))
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent.withValues(alpha: 0.2), AppColors.bgDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accent,
                        backgroundImage: logo != null ? NetworkImage(ApiConstants.buildImageUrl(logo)!) : null,
                        child: logo == null ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white)) : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        role,
                        style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w500),
                      ),
                      if (user['manager_average_rating'] != null && user['manager_average_rating'] > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${user['manager_average_rating']} Rating',
                                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: const TextStyle(color: AppColors.textPrimary, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text('Joined $joinedDate', style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  if (_portfolio.isEmpty)
                    const Text('No events in portfolio yet.', style: TextStyle(color: AppColors.textMuted))
                  else
                    ..._portfolio.map((e) => _buildPortfolioEventCard(e)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioEventCard(dynamic event) {
    final title = event['title'] ?? 'Untitled';
    final dateStr = event['start_time'];
    String formattedDate = '';
    if (dateStr != null) {
      try {
        formattedDate = DateFormat.yMMMd().format(DateTime.parse(dateStr));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event, color: AppColors.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  if (formattedDate.isNotEmpty)
                    Text(formattedDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
