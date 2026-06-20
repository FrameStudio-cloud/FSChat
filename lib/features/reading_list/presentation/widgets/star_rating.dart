import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final void Function(int rating)? onTap;

  const StarRating({
    super.key,
    this.rating = 0,
    this.size = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(star) : null,
          child: Padding(
            padding: EdgeInsets.only(right: i < 4 ? 2 : 0),
            child: Icon(
              star <= rating ? Icons.star : Icons.star_border,
              size: size,
              color: star <= rating
                  ? Colors.amber
                  : colorScheme.onSurfaceVariant.withAlpha(120),
            ),
          ),
        );
      }),
    );
  }
}
