import 'package:flutter/material.dart';

import '../pages/home_page.dart';

/// Reusable star rating display widget.
///
/// [rating] — average rating (0.0–5.0)
/// [count]  — number of reviews
/// [compact] — if true, uses smaller stars (for cards)
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.count = 0,
    this.compact = false,
  });

  final double rating;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final starSize = compact ? 14.0 : 18.0;
    final fontSize = compact ? 12.0 : 14.0;

    if (count == 0 && rating == 0) {
      return Text(
        compact ? 'New' : 'No reviews yet',
        style: TextStyle(color: HomePage.textMuted, fontSize: fontSize),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= rating.round()
                ? Icons.star_rounded
                : (i - 1 < rating && rating - (i - 1) >= 0.25)
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: starSize,
            color: const Color(0xFFF59E0B),
          ),
        const SizedBox(width: 4),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : '0.0',
          style: TextStyle(
            color: HomePage.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 2),
          Text(
            '($count)',
            style: TextStyle(
              color: HomePage.textMuted,
              fontSize: fontSize,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive star selector for review submission.
class StarSelector extends StatelessWidget {
  const StarSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: const Color(0xFFF59E0B),
            ),
          ),
        );
      }),
    );
  }
}
