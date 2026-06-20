import 'package:flutter/material.dart';

class TagChipRow extends StatelessWidget {
  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String> onTagSelected;
  final bool compact;

  const TagChipRow({
    super.key,
    required this.tags,
    this.selectedTag,
    required this.onTagSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 16, vertical: 8),
      child: Row(
        children: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text('All'),
                onPressed: () => onTagSelected(''),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: selectedTag == null || selectedTag!.isEmpty
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: selectedTag == null || selectedTag!.isEmpty
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ...tags.map((tag) {
            final isSelected = selectedTag == tag;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(tag),
                onPressed: () => onTagSelected(tag),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
