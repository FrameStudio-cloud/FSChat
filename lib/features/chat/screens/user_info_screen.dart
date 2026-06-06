import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/message_model.dart';

class UserInfoScreen extends StatefulWidget {
  final ChatUser user;
  final String chatId;

  const UserInfoScreen({
    super.key,
    required this.user,
    required this.chatId,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final DatabaseService _db = DatabaseService();
  ChatUser? _liveUser;
  StreamSubscription? _mediaSub;
  List<Message> _mediaMessages = [];

  @override
  void initState() {
    super.initState();
    _liveUser = widget.user;
    _db.userStream(widget.user.uid).listen((u) {
      if (mounted && u != null) setState(() => _liveUser = u);
    });
    _mediaSub = _db.sharedMediaStream(widget.chatId).listen((msgs) {
      if (mounted) setState(() => _mediaMessages = msgs);
    });
  }

  @override
  void dispose() {
    _mediaSub?.cancel();
    super.dispose();
  }

  String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      return 'today at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Info'),
      ),
      body: ListView(
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          const SizedBox(height: 16),
          _buildInfoSection(context, isDark),
          const SizedBox(height: 16),
          _buildMediaSection(context, isDark),
          const SizedBox(height: 16),
          _buildDangerSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = _liveUser!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: user.photoUrl.isNotEmpty
                ? () => _showMediaViewer(context, [user.photoUrl], 0)
                : null,
            child: Hero(
              tag: 'avatar_${user.uid}',
              child: CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFF075E54),
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? Text(user.name[0].toUpperCase(),
                        style:
                            const TextStyle(fontSize: 40, color: Colors.white))
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (user.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                user.bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      user.online ? const Color(0xFF25D366) : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                user.online
                    ? 'Online'
                    : 'Last seen ${user.lastSeen != null ? _formatLastSeen(user.lastSeen!) : 'unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      user.online ? const Color(0xFF25D366) : Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionChip(
            context,
            icon: Icons.phone_rounded,
            label: 'Voice',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call coming soon')),
            ),
          ),
          _actionChip(
            context,
            icon: Icons.videocam_rounded,
            label: 'Video',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call coming soon')),
            ),
          ),
          _actionChip(
            context,
            icon: Icons.message_rounded,
            label: 'Message',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF075E54), size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF075E54))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isDark) {
    final user = _liveUser!;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('INFO',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500])),
          ),
          if (user.email.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SHARED MEDIA',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 12),
          if (_mediaMessages.isEmpty)
            SizedBox(
              height: 80,
              child: Center(
                child: Text('No shared media yet',
                    style: TextStyle(color: Colors.grey[400])),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaMessages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final msg = _mediaMessages[i];
                  if (msg.type == 'image') {
                    final imageUrls = _mediaMessages
                        .where((m) => m.type == 'image' && m.mediaUrl != null)
                        .map((m) => m.mediaUrl!)
                        .toList();
                    final idx = imageUrls.indexOf(msg.mediaUrl!);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: () => _showMediaViewer(context, imageUrls, idx),
                        child: Image.network(
                          msg.mediaUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic,
                            color: const Color(0xFF075E54), size: 28),
                        const SizedBox(height: 4),
                        Text(
                          msg.duration != null ? '${msg.duration}s' : 'Audio',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showMediaViewer(
      BuildContext context, List<String> urls, int initialIndex) {
    if (urls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: PageView(
            controller: PageController(initialPage: initialIndex),
            children: urls
                .map((url) => InteractiveViewer(
                      child: Image.network(url, fit: BoxFit.contain),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ACTIONS',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500])),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            title:
                const Text('Clear chat', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Delete all messages'),
            onTap: () => _confirmClearChat(context),
          ),
          ListTile(
            leading: const Icon(Icons.block_rounded, color: Colors.red),
            title:
                const Text('Block user', style: TextStyle(color: Colors.red)),
            subtitle: const Text('They won\'t be able to message you'),
            onTap: () => _confirmBlockUser(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearChat(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat'),
        content: const Text('Delete all messages in this conversation?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.clearChat(widget.chatId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat cleared')),
        );
      }
    }
  }

  Future<void> _confirmBlockUser(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block user'),
        content: Text(
            'Block ${_liveUser?.name ?? widget.user.name}? They won\'t be able to send you messages.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final uid = context.read<AuthProvider>().user!.uid;
      await _db.blockUser(uid, widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_liveUser?.name ?? widget.user.name} blocked')),
        );
      }
    }
  }
}
