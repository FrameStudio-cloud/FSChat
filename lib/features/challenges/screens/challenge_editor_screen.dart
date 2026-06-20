import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/challenge_model.dart';

class ChallengeEditorScreen extends StatefulWidget {
  const ChallengeEditorScreen({super.key});

  @override
  State<ChallengeEditorScreen> createState() => _ChallengeEditorScreenState();
}

class _ChallengeEditorScreenState extends State<ChallengeEditorScreen> {
  final _db = DatabaseService();
  final _uuid = Uuid();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _taskController = TextEditingController();
  List<String> _tasks = [];
  List<String> _selectedParticipants = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isSubmitting = false;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 6));
    _loadUsers();
  }

  void _loadUsers() {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    _db.allUsers(uid).listen((users) {
      if (mounted) {
        setState(() => _allUsers =
            users.map((u) => {'id': u.uid, 'name': u.name}).toList());
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final uid = context.watch<AuthProvider>().user?.uid;
    final currentName = context.watch<AuthProvider>().chatUser?.name ?? 'Me';
    final isFormValid = _titleController.text.trim().isNotEmpty &&
        _tasks.isNotEmpty &&
        (_selectedParticipants.isNotEmpty || uid != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Challenge'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: isFormValid && !_isSubmitting ? _submit : null,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: theme.textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: 'Challenge title',
                hintText: 'e.g. 7-Day Gratitude',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Participants', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (uid != null)
                  FilterChip(
                    label: Text('$currentName (you)'),
                    selected: true,
                    onSelected: null,
                    selectedColor: colorScheme.primary.withAlpha(40),
                    side: BorderSide.none,
                  ),
                ..._allUsers.map((user) {
                  final isSelected = _selectedParticipants.contains(user['id']);
                  return FilterChip(
                    label: Text(user['name'] as String),
                    selected: isSelected,
                    onSelected: (s) => setState(() {
                      if (s) {
                        _selectedParticipants.add(user['id'] as String);
                      } else {
                        _selectedParticipants.remove(user['id']);
                      }
                    }),
                    selectedColor: colorScheme.primary.withAlpha(40),
                    side: BorderSide.none,
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            Text('Daily Tasks', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Write 100 words',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tasks.isNotEmpty)
              ..._tasks.asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 11)),
                    ),
                    title: Text(task, style: theme.textTheme.bodyMedium),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _tasks.removeAt(i)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(text);
      _taskController.clear();
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.user!.uid;
      final name = auth.chatUser?.name ?? 'Me';

      final participantIds = [uid, ..._selectedParticipants];
      final participantNames = <String, String>{};
      participantNames[uid] = name;
      for (final u in _allUsers) {
        if (_selectedParticipants.contains(u['id'])) {
          participantNames[u['id'] as String] = u['name'] as String;
        }
      }

      final challenge = Challenge(
        id: _uuid.v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        createdBy: uid,
        participants: participantIds,
        participantNames: participantNames,
        startDate: _startDate,
        endDate: _endDate,
        tasks: _tasks,
        createdAt: DateTime.now(),
      );
      await _db.createChallenge(challenge);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
