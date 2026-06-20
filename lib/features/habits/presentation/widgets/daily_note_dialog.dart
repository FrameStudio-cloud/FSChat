import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/models/habit_model.dart';

class DailyNoteDialog extends StatefulWidget {
  final DateTime date;
  final List<HabitLog> logs;
  final List<Habit> habits;
  final Future<void> Function(String habitFirestoreId, String note) onSaveNote;

  const DailyNoteDialog({
    super.key,
    required this.date,
    required this.logs,
    required this.habits,
    required this.onSaveNote,
  });

  @override
  State<DailyNoteDialog> createState() => _DailyNoteDialogState();
}

class _DailyNoteDialogState extends State<DailyNoteDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final log in widget.logs) {
      _controllers[log.habitFirestoreId] =
          TextEditingController(text: log.note);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, MMMM d').format(widget.date),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...widget.logs.map((log) {
            final habit = widget.habits.firstWhere(
              (h) => h.firestoreId == log.habitFirestoreId,
              orElse: () => widget.habits.first,
            );
            final controller = _controllers[log.habitFirestoreId]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      color: Color(
                          int.parse(habit.colorHex.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: controller,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Add a note...',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (value) =>
                              widget.onSaveNote(log.habitFirestoreId, value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
