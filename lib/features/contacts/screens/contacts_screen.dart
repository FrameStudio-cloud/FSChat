import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _db.allUsers(currentUid),
              builder: (_, snapshot) {
                final users = snapshot.data ?? [];
                final filtered = _searchQuery.isEmpty
                    ? users
                    : users
                        .where(
                            (u) => u.name.toLowerCase().contains(_searchQuery))
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
                      subtitle: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user.online
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.online ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: user.online
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final chatId =
                            await _db.getOrCreateChat(currentUid, user.uid);
                        if (!context.mounted) return;
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'chatId': chatId,
                            'otherUser': user,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
