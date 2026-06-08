import 'package:flutter/material.dart';
import '../models/sticker_model.dart';
import '../services/sticker_service.dart';

class StickerSuggestionBar extends StatelessWidget {
  final String query;
  final void Function(Sticker sticker) onStickerSelected;

  const StickerSuggestionBar({
    super.key,
    required this.query,
    required this.onStickerSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (query.length < 2) return const SizedBox.shrink();

    final matches = _findMatches(query);
    if (matches.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2D2D2D)
            : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Stickers',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final sticker = matches[i];
                return GestureDetector(
                  onTap: () => onStickerSelected(sticker),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: StickerService.stickerPreview(
                        sticker.packId,
                        sticker.id,
                        localPath: sticker.localPath,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Sticker> _findMatches(String query) {
    final lower = query.toLowerCase();
    final service = StickerService.instance;
    final results = <Sticker>[];
    for (final pack in service.packs) {
      for (final sticker in pack.stickers) {
        if (sticker.tags.any((tag) => tag.toLowerCase().contains(lower))) {
          results.add(sticker);
        }
      }
    }
    return results.take(6).toList();
  }
}
