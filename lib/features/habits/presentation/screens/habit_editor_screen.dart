import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/habit_model.dart';
import '../../domain/habit_notifier.dart';

class HabitEditorScreen extends StatefulWidget {
  final Habit? existingHabit;

  const HabitEditorScreen({super.key, this.existingHabit});

  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedColor = '#075E54';
  String _selectedFrequency = 'daily';
  List<String> _customDays = [];

  bool get _isEditing => widget.existingHabit != null;

  static const _colorOptions = [
    '#075E54',
    '#E65100',
    '#1565C0',
    '#7B1FA2',
    '#C62828',
    '#2E7D32',
    '#F9A825',
    '#00695C',
  ];

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final h = widget.existingHabit!;
      _nameController.text = h.name;
      _selectedColor = h.colorHex;
      _selectedFrequency = h.frequency;
      _customDays = List.from(h.customDays);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
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
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              style: theme.textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Morning journal',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Color',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((hex) {
                final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = hex);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withAlpha(100),
                                  blurRadius: 8,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Frequency',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _FrequencyOption(
              label: 'Daily',
              icon: Icons.calendar_view_day,
              selected: _selectedFrequency == 'daily',
              onTap: () => setState(() => _selectedFrequency = 'daily'),
            ),
            const SizedBox(height: 8),
            _FrequencyOption(
              label: 'Weekly',
              icon: Icons.calendar_view_week,
              selected: _selectedFrequency == 'weekly',
              onTap: () => setState(() => _selectedFrequency = 'weekly'),
            ),
            const SizedBox(height: 8),
            _FrequencyOption(
              label: 'Custom days',
              icon: Icons.event_repeat,
              selected: _selectedFrequency == 'custom',
              onTap: () => setState(() {
                _selectedFrequency = 'custom';
                if (_customDays.isEmpty) _customDays = ['Mon', 'Wed', 'Fri'];
              }),
            ),
            if (_selectedFrequency == 'custom') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dayLabels.map((day) {
                  final isSelected = _customDays.contains(day);
                  return FilterChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _customDays.add(day);
                        } else {
                          _customDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: _confirmArchive,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive this habit'),
                  style:
                      TextButton.styleFrom(foregroundColor: colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final uid = context.read<AuthProvider>().user!.uid;
      final notifier = context.read<HabitNotifier>();

      if (_isEditing) {
        await notifier.updateHabit(
          widget.existingHabit!.firestoreId,
          name: name,
          colorHex: _selectedColor,
          frequency: _selectedFrequency,
          customDays: _selectedFrequency == 'custom' ? _customDays : null,
        );
      } else {
        await notifier.createHabit(
          userId: uid,
          name: name,
          colorHex: _selectedColor,
          frequency: _selectedFrequency,
          customDays: _selectedFrequency == 'custom' ? _customDays : [],
        );
      }
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _confirmArchive() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive habit?'),
        content: const Text('You can restore it later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = context.read<HabitNotifier>();
              await notifier.archiveHabit(widget.existingHabit!.firestoreId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
