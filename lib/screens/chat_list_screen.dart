import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF075E54),
                    backgroundImage: chatUser.photoUrl.isNotEmpty
                        ? NetworkImage(chatUser.photoUrl)
                        : null,
                    child: chatUser.photoUrl.isEmpty
                        ? Text(
                            chatUser.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            if (chatUser != null) const SizedBox(width: 10),
            const Text('FSChat'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: StreamBuilder(
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
              final otherUid =
                  chat.participants.firstWhere((p) => p != currentUid);

              return StreamBuilder(
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
                    child: ChatTile(
                      chat: chat,
                      otherUser: otherUser,
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context, db, currentUid),
        backgroundColor: const Color(0xFF075E54),
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
                  const Color(0xFF075E54).withValues(alpha: 0.2),
                  const Color(0xFF25D366).withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: const Color(0xFF075E54).withValues(alpha: 0.4),
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
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF075E54),
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            )
                          : null,
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
