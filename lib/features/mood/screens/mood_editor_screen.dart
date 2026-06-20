import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/mood_entry.dart';

class MoodEditorScreen extends StatefulWidget {
  final DateTime initialDate;
  const MoodEditorScreen({super.key, required this.initialDate});

  @override
  State<MoodEditorScreen> createState() => _MoodEditorScreenState();
}

class _MoodEditorScreenState extends State<MoodEditorScreen> {
  final _db = DatabaseService();
  final _uuid = Uuid();
  final _noteController = TextEditingController();
  late DateTime _selectedDate;
  String _selectedEmoji = MoodEntry.moods[2].emoji;
  String _selectedLabel = MoodEntry.moods[2].label;
  Set<String> _selectedTags = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mood for ${DateFormat('MMM d').format(_selectedDate)}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _isSubmitting ? null : _save,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling?',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: MoodEntry.moods.map((mood) {
                final isSelected = _selectedEmoji == mood.emoji;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedEmoji = mood.emoji;
                    _selectedLabel = mood.label;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 64,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(mood.color).withAlpha(30)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: Color(mood.color), width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                        Text(mood.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Color(mood.color)
                                  : colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Notes (optional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'What happened today?',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tags', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Pain',
                'Psychology',
                'Body',
                'Strength',
                'Weakness',
              ].map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (s) => setState(() {
                    if (s) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  }),
                  selectedColor: colorScheme.primary.withAlpha(40),
                  checkmarkColor: colorScheme.primary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSubmitting = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final entry = MoodEntry(
        id: _uuid.v4(),
        userId: uid,
        emoji: _selectedEmoji,
        label: _selectedLabel,
        note: _noteController.text.trim(),
        tags: _selectedTags.toList(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );
      await _db.saveMood(entry);
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
