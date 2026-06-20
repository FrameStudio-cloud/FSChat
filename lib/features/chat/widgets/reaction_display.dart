import 'package:flutter/material.dart';

class ReactionDisplay extends StatelessWidget {
  final Map<String, String> reactions;
  final String currentUserId;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final grouped = <String, int>{};
    for (final e in reactions.values) {
      grouped[e] = (grouped[e] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 4,
        children: grouped.entries.map((e) {
          final isSelf = reactions.entries
              .any((r) => r.value == e.key && r.key == currentUserId);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelf
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: isSelf
                  ? Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4))
                  : null,
            ),
            child: Text(
              '${e.key}${e.value > 1 ? ' ${e.value}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }
}
