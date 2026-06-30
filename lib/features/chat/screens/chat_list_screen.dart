import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../models/chat_model.dart';
import '../widgets/chat_tile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final db = DatabaseService();
    final currentUid = auth.user!.uid;
    final chatUser = auth.chatUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (chatUser != null)
              Stack(
                children: [
                  avatarWidget(
                    radius: 16,
                    photoUrl: chatUser.photoUrl,
                    name: chatUser.name,
                  ),
                ],
              ),
            if (chatUser != null) const SizedBox(width: 10),
            const Text('FSChat'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              switch (value) {
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                case 'mark_read':
                  final db = DatabaseService();
                  await db.markAllChatsRead(currentUid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All chats marked as read'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                case 'archive':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No archived chats'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_rounded),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Archive'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PopupMenuItem(
                value: 'mark_read',
                child: ListTile(
                  leading:
                      Icon(Icons.done_all_rounded, color: AppColors.online),
                  title: const Text('Mark all read'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _WidgetBubbles(uid: currentUid),
          Expanded(
            child: StreamBuilder(
              stream: db.userChats(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 80,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chats[index];

                    if (chat.isGroup) {
                      return RepaintBoundary(
                        child: Dismissible(
                          key: Key(chat.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: Colors.red,
                            child: const Icon(Icons.delete_rounded,
                                color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete chat'),
                                content: Text(
                                    'Delete the group "${chat.groupName}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) => db.deleteChat(chat.id),
                          child: StreamBuilder<int>(
                            stream: db.unreadCountStream(chat.id, currentUid),
                            builder: (_, unreadSnap) {
                              final unreadCount = unreadSnap.data ?? 0;
                              return ChatTile(
                                chat: chat,
                                otherUser: null,
                                unreadCount: unreadCount,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: {
                                      'chatId': chat.id,
                                      'isGroup': true,
                                      'groupName': chat.groupName,
                                      'groupPhoto': chat.groupPhoto,
                                    },
                                  );
                                },
                                onLongPress: () =>
                                    _showGroupMenu(context, chat, db),
                              );
                            },
                          ),
                        ),
                      );
                    }

                    final otherUid =
                        chat.participants.firstWhere((p) => p != currentUid);

                    return RepaintBoundary(
                      child: StreamBuilder(
                        stream: db.userStream(otherUid),
                        builder: (_, userSnap) {
                          final otherUser = userSnap.data;
                          if (otherUser == null) return const SizedBox();

                          return Dismissible(
                            key: Key(chat.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: Colors.red,
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete chat'),
                                  content: Text(
                                      'Delete conversation with ${otherUser.name}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => db.deleteChat(chat.id),
                            child: StreamBuilder<int>(
                              stream: db.unreadCountStream(chat.id, currentUid),
                              builder: (_, unreadSnap) {
                                final unreadCount = unreadSnap.data ?? 0;
                                return ChatTile(
                                  chat: chat,
                                  otherUser: otherUser,
                                  unreadCount: unreadCount,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/chat',
                                      arguments: {
                                        'chatId': chat.id,
                                        'otherUser': otherUser,
                                      },
                                    );
                                  },
                                  onLongPress: () => _showChatMenu(
                                      context, chat, otherUser, db),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context, db, currentUid),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        child: const Icon(Icons.message_rounded),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE65100).withValues(alpha: 0.2),
                  const Color(0xFF25D366).withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: const Color(0xFFE65100).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to start a new chat',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showChatMenu(
      BuildContext context, Chat chat, ChatUser otherUser, DatabaseService db) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                chat.pinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: const Color(0xFFE65100),
              ),
              title: Text(chat.pinned ? 'Unpin chat' : 'Pin chat'),
              onTap: () {
                Navigator.pop(ctx);
                db.togglePinChat(chat.id, !chat.pinned);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete chat',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                db.deleteChat(chat.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showGroupMenu(BuildContext context, Chat chat, DatabaseService db) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFFE65100)),
              title: const Text('Group info'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/chat', arguments: {
                  'chatId': chat.id,
                  'isGroup': true,
                  'groupName': chat.groupName,
                  'groupPhoto': chat.groupPhoto,
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete group',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                db.deleteChat(chat.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNewChatDialog(
      BuildContext screenContext, DatabaseService db, String currentUid) {
    showModalBottomSheet(
      context: screenContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return _NewChatSheet(
              db: db,
              currentUid: currentUid,
              screenContext: screenContext,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
// Widget Bubbles Row
// ═══════════════════════════════════════════

class _WidgetBubbles extends StatelessWidget {
  final String uid;
  const _WidgetBubbles({required this.uid});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _BubbleChip(
            icon: Icons.emoji_emotions_outlined,
            iconColor: const Color(0xFFFF9800),
            value: FutureBuilder<String>(
              future: db
                  .getMoodForDate(uid, today)
                  .then((m) => m?.label ?? 'Check in'),
              builder: (_, snap) => Text(
                snap.data ?? '—',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
            ),
            label: "Today's mood",
            onTap: () => Navigator.pushNamed(context, '/mood'),
          ),
          const SizedBox(width: 8),
          _BubbleChip(
            icon: Icons.task_alt,
            iconColor: const Color(0xFF25D366),
            value: FutureBuilder<String>(
              future: db
                  .getCompletedHabitsToday(today)
                  .then((n) => n.toString())
                  .catchError((_) => '—'),
              builder: (_, snap) => Text(
                snap.data ?? '—',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
            ),
            label: 'Habits done',
            onTap: () => Navigator.pushNamed(context, '/habits'),
          ),
          const SizedBox(width: 8),
          _BubbleChip(
            icon: Icons.edit_note,
            iconColor: const Color(0xFFE65100),
            value: const Text('New',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3)),
            label: 'Journal post',
            onTap: () => Navigator.pushNamed(context, '/blog/create'),
          ),
          const SizedBox(width: 8),
          _BubbleChip(
            icon: Icons.emoji_events_outlined,
            iconColor: const Color(0xFF9C27B0),
            value: FutureBuilder<int>(
              future: db.getActiveChallengesCount(uid),
              builder: (_, snap) => Text(
                '${snap.data ?? 0}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
            ),
            label: 'Challenges',
            onTap: () => Navigator.pushNamed(context, '/challenges'),
          ),
          const SizedBox(width: 8),
          _BubbleChip(
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFF2196F3),
            value: const Text('Open',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3)),
            label: 'Reading list',
            onTap: () => Navigator.pushNamed(context, '/reading'),
          ),
          const SizedBox(width: 8),
          _BubbleChip(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF00BCD4),
            value: FutureBuilder<int>(
              future: db.countOnlineUsers(uid),
              builder: (_, snap) => Text(
                '${snap.data ?? 0}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3),
              ),
            ),
            label: 'Online now',
            onTap: () => Navigator.pushNamed(context, '/contacts'),
          ),
        ],
      ),
    );
  }
}

class _BubbleChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget value;
  final String label;
  final VoidCallback onTap;

  const _BubbleChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(100)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  value,
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  final DatabaseService db;
  final String currentUid;
  final BuildContext screenContext;
  final ScrollController scrollController;

  const _NewChatSheet({
    required this.db,
    required this.currentUid,
    required this.screenContext,
    required this.scrollController,
  });

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'New Conversation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child:
                const Icon(Icons.group_add_rounded, color: Color(0xFFE65100)),
          ),
          title: const Text('New group',
              style: TextStyle(fontWeight: FontWeight.w500)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/create_group');
          },
        ),
        const Divider(indent: 72, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: widget.db.allUsers(widget.currentUid),
            builder: (_, snapshot) {
              final users = snapshot.data ?? [];
              final filtered = _searchQuery.isEmpty
                  ? users
                  : users
                      .where((u) => u.name.toLowerCase().contains(_searchQuery))
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No other users found'
                        : 'No contacts match your search',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }

              return ListView.separated(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                ),
                itemBuilder: (_, i) {
                  final user = filtered[i];
                  return ListTile(
                    leading: avatarWidget(
                      radius: 24,
                      photoUrl: user.photoUrl,
                      name: user.name,
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: user.online
                        ? Text(
                            'Online',
                            style: TextStyle(
                              color: const Color(0xFF25D366),
                              fontSize: 13,
                            ),
                          )
                        : null,
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () async {
                      Navigator.pop(context);
                      final chatId = await widget.db.getOrCreateChat(
                        widget.currentUid,
                        user.uid,
                      );
                      if (widget.screenContext.mounted) {
                        Navigator.pushNamed(
                          widget.screenContext,
                          '/chat',
                          arguments: {
                            'chatId': chatId,
                            'otherUser': user,
                          },
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
