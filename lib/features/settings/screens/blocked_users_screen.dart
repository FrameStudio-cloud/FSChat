import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/database_service.dart';
import '../../../shared/utils/avatar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _db = DatabaseService();
  List<ChatUser> _blockedUsers = [];
  bool _loading = true;
  StreamSubscription? _streamSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    final users = await _db.getBlockedUsers(uid);
    if (mounted) {
      setState(() {
        _blockedUsers = users;
        _loading = false;
      });
    }
    _streamSub = _db.blockedUserIdsStream(uid).listen((ids) async {
      if (ids.isEmpty) {
        if (mounted) setState(() => _blockedUsers = []);
        return;
      }
      final updated = await _db.getBlockedUsers(uid);
      if (mounted) setState(() => _blockedUsers = updated);
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _unblock(ChatUser user) async {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    await _db.unblockUser(uid, user.uid);
    if (mounted) {
      setState(() => _blockedUsers.removeWhere((u) => u.uid == user.uid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unblocked ${user.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_rounded,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No blocked users',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[500])),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _blockedUsers.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, indent: 72, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return ListTile(
                      leading: avatarWidget(
                        radius: 24,
                        photoUrl: user.photoUrl,
                        name: user.name,
                      ),
                      title: Text(user.name),
                      subtitle: user.email.isNotEmpty
                          ? Text(user.email,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]))
                          : null,
                      trailing: TextButton(
                        onPressed: () => _unblock(user),
                        child: const Text('Unblock'),
                      ),
                    );
                  },
                ),
    );
  }
}
