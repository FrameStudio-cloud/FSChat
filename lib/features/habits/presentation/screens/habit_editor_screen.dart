import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/habit_model.dart';
import '../../domain/habit_notifier.dart';

class HabitEditorScreen extends StatefulWidget {
  final Habit? existingHabit;
  final HabitNotifier notifier;
  final String userId;

  const HabitEditorScreen({
    super.key,
    this.existingHabit,
    required this.notifier,
    required this.userId,
  });

  @override
  State<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _HabitEditorScreenState extends State<HabitEditorScreen> {
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  bool _isSubmitting = false;
  String _selectedColor = '#075E54';
  String _selectedFrequency = 'daily';
  List<String> _customDays = [];
  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  String _selectedCategory = 'General';
  String _habitType = 'boolean';

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

  static const _categoryOptions = [
    'General',
    'Health',
    'Mind',
    'Productivity',
    'Fitness',
    'Social',
    'Finance',
    'Learning',
    'Creative',
    'Self-care',
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
      _reminderEnabled = h.reminderEnabled;
      _reminderHour = h.reminderHour;
      _reminderMinute = h.reminderMinute;
      _selectedCategory =
          _categoryOptions.contains(h.category) ? h.category : 'General';
      _habitType = h.habitType;
      _targetController.text =
          h.targetCount.isFinite ? h.targetCount.toInt().toString() : '1';
      _unitController.text = h.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isQuantifiable = _habitType == 'quantifiable';

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
            // Name
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              style: theme.textTheme.titleLarge,
              decoration: InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Drink Water',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Type toggle
            Text('Type',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _habitType = 'boolean'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isQuantifiable
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18,
                                color: !isQuantifiable
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('Boolean',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: !isQuantifiable
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _habitType = 'quantifiable'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isQuantifiable
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.exposure,
                                size: 18,
                                color: isQuantifiable
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('Quantifiable',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isQuantifiable
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quantifiable fields
            if (isQuantifiable) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Target',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit (e.g. glasses, min)',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Category
            Text('Category',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _categoryOptions.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedCategory = v);
              },
            ),

            const SizedBox(height: 20),

            // Color
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

            // Frequency
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
                if (_customDays.isEmpty) {
                  _customDays = ['Mon', 'Wed', 'Fri'];
                }
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

            const SizedBox(height: 20),

            // Reminder
            SwitchListTile(
              title: const Text('Daily Reminder'),
              subtitle: Text(
                _reminderEnabled
                    ? '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}'
                    : 'Tap to set a daily reminder',
              ),
              value: _reminderEnabled,
              onChanged: (val) => setState(() => _reminderEnabled = val),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickReminderTime,
                  icon: const Icon(Icons.access_time_rounded),
                  label: Text(
                    '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
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

  Future<void> _pickReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (time != null) {
      setState(() {
        _reminderHour = time.hour;
        _reminderMinute = time.minute;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final raw = double.tryParse(_targetController.text.trim()) ?? 1.0;
    final target = (raw.isFinite && raw >= 0) ? raw : 1.0;

    setState(() => _isSubmitting = true);
    try {
      if (_isEditing) {
        await widget.notifier.updateHabit(
          widget.existingHabit!.firestoreId,
          name: name,
          colorHex: _selectedColor,
          frequency: _selectedFrequency,
          customDays: _selectedFrequency == 'custom' ? _customDays : null,
          reminderEnabled: _reminderEnabled,
          reminderHour: _reminderHour,
          reminderMinute: _reminderMinute,
          category: _selectedCategory,
          habitType: _habitType,
          targetCount: target,
          unit: _unitController.text.trim(),
        );
      } else {
        await widget.notifier.createHabit(
          userId: widget.userId,
          name: name,
          colorHex: _selectedColor,
          frequency: _selectedFrequency,
          customDays: _selectedFrequency == 'custom' ? _customDays : [],
          reminderEnabled: _reminderEnabled,
          reminderHour: _reminderHour,
          reminderMinute: _reminderMinute,
          category: _selectedCategory,
          habitType: _habitType,
          targetCount: target,
          unit: _unitController.text.trim(),
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
              await widget.notifier
                  .archiveHabit(widget.existingHabit!.firestoreId);
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
