import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'user/my_tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<dynamic> _notifications = [];
  bool _loadingNotifications = false;
  int _unreadCount = 0;
  bool _isUploadingImage = false;
  List<String> _selectedInterests = [];
  final List<String> _allCategories = ['Technical', 'Workshop', 'Conference', 'Seminar', 'Cultural', 'Business', 'AI', 'Networking', 'FinTech', 'Innovation', 'Sustainability', 'Entrepreneurship'];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loadingNotifications = true);
    try {
      final api = ApiService();
      final res = await api.get('/notifications');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Backend returns { notifications: [...], unread_count: N }
        if (data is Map && data['notifications'] != null) {
          setState(() {
            _notifications = data['notifications'];
            _unreadCount = data['unread_count'] ?? 0;
          });
        } else if (data is List) {
          setState(() {
            _notifications = data;
            _unreadCount = data.where((n) => n['read_at'] == null).length;
          });
        }
      }
    } catch (_) {}
    setState(() => _loadingNotifications = false);
  }

  Future<void> _markAsRead(dynamic id) async {
    try {
      final api = ApiService();
      await api.put('/notifications/$id/read');
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final api = ApiService();
      await api.put('/notifications/read-all');
      _fetchNotifications();
    } catch (_) {}
  }

  Future<void> _pickAndUploadImage(AuthProvider auth) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final api = ApiService();
      
      final byteData = await image.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'logo', 
        byteData,
        filename: 'profile_picture.jpg',
      );

      final res = await api.multipart(
        'POST', 
        '/profile?_method=PUT', 
        {
          'name': auth.userName ?? '',
          'email': auth.userEmail ?? '',
        },
        file: multipartFile
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['user'] != null) {
          await auth.updateUser(data['user']);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!'), backgroundColor: AppColors.success),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image'), backgroundColor: AppColors.danger),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final ticketProv = Provider.of<TicketProvider>(context);
    final user = auth.user;
    final name = auth.userName;
    final userImage = user?['profile']?['logo'];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: userImage != null ? NetworkImage(ApiConstants.buildImageUrl(userImage)!) : null,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      child: userImage == null ? const Icon(Icons.person, size: 20) : null,
                    ),
                    GestureDetector(
                      onTap: () => _showNotificationsSheet(context),
                      child: Stack(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.accent2, size: 28),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 0, top: 0,
                              child: Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Profile Header ──
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: userImage != null ? NetworkImage(ApiConstants.buildImageUrl(userImage)!) : null,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      child: _isUploadingImage 
                        ? const CircularProgressIndicator(color: AppColors.accent)
                        : (userImage == null ? Text(name[0], style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)) : null),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickAndUploadImage(auth),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent2,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bgDark, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
              const Text('Tech Enthusiast & Attendee', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent2.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent2.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified, size: 14, color: AppColors.accent2),
                    SizedBox(width: 4),
                    Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent2)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Ticket History ──
              _buildSectionTitle('Ticket History', 'View All', onTapAction: () {
                // Navigate to MyTicketsScreen
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyTicketsScreen()));
              }),
              const SizedBox(height: 12),
              ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ticketProv.myTickets.length > 3 ? 3 : ticketProv.myTickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildTicketHistoryItem(ticketProv.myTickets[i]),
              ),
              const SizedBox(height: 32),

              // ── Interests ──
              _buildSectionTitle('Interests', 'Edit', onTapAction: () => _showInterestsDialog()),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: _selectedInterests.isEmpty ? const EdgeInsets.all(20) : const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _selectedInterests.isEmpty 
                    ? const Center(child: Text('No interests added yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedInterests.map((interest) => _buildInterestTag(interest)).toList(),
                      ),
                ),
              ),
              const SizedBox(height: 32),

              const SizedBox(height: 32),

              // ── Buttons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showEditProfileDialog(context, auth),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accent2.withValues(alpha: 0.5)),
                          gradient: LinearGradient(
                            colors: [AppColors.accent2.withValues(alpha: 0.1), Colors.transparent],
                          ),
                        ),
                        child: const Center(child: Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent2))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _showLogoutDialog(context, auth),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: const Center(child: Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String? action, {VoidCallback? onTapAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          if (action != null)
            GestureDetector(
              onTap: onTapAction,
              child: Text(action, style: const TextStyle(fontSize: 14, color: AppColors.accent2)),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketHistoryItem(Map<String, dynamic> ticket) {
    final event = ticket['event'] ?? {};
    final title = event['title'] ?? 'Untitled';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.accent.withValues(alpha: 0.1)),
            child: const Icon(Icons.event_available_rounded, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Text('May 15-17', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildInterestTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildFavoriteItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ─── Edit Profile Dialog ──────────────────────
  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.userName);
    final emailCtrl = TextEditingController(text: auth.userEmail);
    final passCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogLabel('Full Name'),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: _dialogInput('Your full name'),
                ),
                const SizedBox(height: 16),
                _dialogLabel('Email Address'),
                const SizedBox(height: 6),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dialogInput('you@example.com'),
                ),
                const SizedBox(height: 16),
                _dialogLabel('New Password (optional)'),
                const SizedBox(height: 6),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: _dialogInput('Leave empty to keep current'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        final api = ApiService();
                        final body = <String, dynamic>{
                          'name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                        };
                        if (passCtrl.text.trim().isNotEmpty) {
                          body['password'] = passCtrl.text.trim();
                        }
                        final res = await api.put('/profile', body);
                        final data = jsonDecode(res.body);
                        if (res.statusCode == 200) {
                          // Update local user data
                          await auth.checkAuth();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Profile updated!'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } else {
                          final msg = data['message'] ?? 'Update failed';
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                      setDialogState(() => isLoading = false);
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5));
  }

  InputDecoration _dialogInput(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.4)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  // ─── Notifications Sheet ──────────────────────
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: AppColors.accent2, size: 22),
                  const SizedBox(width: 10),
                  const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const Spacer(),
                  if (_unreadCount > 0) ...[
                    GestureDetector(
                      onTap: () { _markAllRead(); Navigator.pop(ctx); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Mark All Read', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_unreadCount new',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: _loadingNotifications
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              const Text('No notifications yet', style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollCtrl,
                          itemCount: _notifications.length,
                          itemBuilder: (_, i) {
                            final n = _notifications[i];
                            // Laravel Notifications: read_at == null means unread
                            final isRead = n['read_at'] != null;
                            // Data is stored in 'data' field (may be string or map)
                            dynamic nData = n['data'];
                            if (nData is String) {
                              try { nData = jsonDecode(nData); } catch (_) { nData = {}; }
                            }
                            nData ??= {};
                            final title = nData['title']?.toString() ?? '';
                            final message = nData['message']?.toString() ?? n['message']?.toString() ?? '';
                            final icon = nData['icon']?.toString() ?? '🔔';
                            final type = nData['type']?.toString() ?? 'system';

                            Color typeColor;
                            switch (type) {
                              case 'event': typeColor = AppColors.accent; break;
                              case 'sponsorship': typeColor = AppColors.warning; break;
                              case 'ticket': typeColor = AppColors.success; break;
                              case 'verification': typeColor = AppColors.accent2; break;
                              default: typeColor = AppColors.textMuted;
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.transparent : typeColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isRead ? Colors.transparent : typeColor.withValues(alpha: 0.12)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isRead ? AppColors.textMuted : typeColor).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                                ),
                                title: title.isNotEmpty
                                    ? Text(title, style: TextStyle(fontSize: 13, fontWeight: isRead ? FontWeight.w400 : FontWeight.w700, color: AppColors.textPrimary))
                                    : null,
                                subtitle: Text(
                                  message,
                                  style: TextStyle(fontSize: 13, fontWeight: isRead ? FontWeight.w400 : FontWeight.w500, color: isRead ? AppColors.textMuted : AppColors.textPrimary),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                                trailing: !isRead
                                    ? GestureDetector(
                                        onTap: () {
                                          _markAsRead(n['id']);
                                          Navigator.pop(ctx);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.check, size: 16, color: AppColors.success),
                                        ),
                                      )
                                    : Text(_formatDate(n['created_at']), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Interests Dialog ──────────────────────
  void _showInterestsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Interests', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCategories.map((cat) {
                final isSelected = _selectedInterests.contains(cat);
                return GestureDetector(
                  onTap: () {
                    setDialogState(() {
                      if (isSelected) {
                        _selectedInterests.remove(cat);
                      } else {
                        _selectedInterests.add(cat);
                      }
                    });
                    setState(() {}); // Update main screen
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? AppColors.accent : Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Logout Dialog ──────────────────────
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
