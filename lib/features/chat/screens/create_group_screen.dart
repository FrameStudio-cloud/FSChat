import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  final Set<String> _selectedUids = {};
  List<ChatUser> _allUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user!.uid;
    _db.allUsers(uid).first.then((users) {
      if (mounted) setState(() => _allUsers = users);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selectedUids.length >= 2;

  Future<void> _createGroup() async {
    if (!_canCreate) return;
    final currentUid = context.read<AuthProvider>().user!.uid;
    final allParticipants = [currentUid, ..._selectedUids];
    final chatId = await _db.createGroupChat(
      name: _nameController.text.trim(),
      participants: allParticipants,
      adminUid: currentUid,
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/chat',
      arguments: {
        'chatId': chatId,
        'isGroup': true,
        'groupName': _nameController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _searchQuery.isEmpty
        ? _allUsers
        : _allUsers
            .where((u) => u.name.toLowerCase().contains(_searchQuery))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _canCreate ? _createGroup : null,
            child: const Text('Create',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Group name',
                prefixIcon: const Icon(Icons.group_rounded),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Add members...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          if (_selectedUids.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '${_selectedUids.length + 1} participants',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (_, i) {
                final user = filtered[i];
                final selected = _selectedUids.contains(user.uid);
                return ListTile(
                  leading: Stack(
                    children: [
                      avatarWidget(
                        radius: 24,
                        photoUrl: user.photoUrl,
                        name: user.name,
                      ),
                      if (selected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE65100),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  title: Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: user.online
                      ? Text('Online',
                          style: TextStyle(
                              color: const Color(0xFF25D366), fontSize: 13))
                      : null,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedUids.remove(user.uid);
                      } else {
                        _selectedUids.add(user.uid);
                      }
                    });
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
