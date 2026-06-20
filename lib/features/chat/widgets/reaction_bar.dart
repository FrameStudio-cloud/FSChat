import 'package:flutter/material.dart';

const _emojis = ['❤️', '😂', '😮', '😢', '🙏', '👍'];

class ReactionBar extends StatelessWidget {
  final String currentEmoji;
  final ValueChanged<String> onTap;

  const ReactionBar({
    super.key,
    required this.onTap,
    this.currentEmoji = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _emojis.map((e) {
          final selected = e == currentEmoji;
          return GestureDetector(
            onTap: () => onTap(e),
            child: AnimatedScale(
              scale: selected ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(e, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
