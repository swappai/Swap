import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../services/review_service.dart';
import 'star_rating.dart';

/// Dialog for submitting a review after a completed swap.
class ReviewDialog extends StatefulWidget {
  const ReviewDialog({
    super.key,
    required this.swapRequestId,
    required this.reviewerUid,
    this.recipientName,
  });

  final String swapRequestId;
  final String reviewerUid;
  final String? recipientName;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 0;
  final _textCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    try {
      await ReviewService().submitReview(
        reviewerUid: widget.reviewerUid,
        swapRequestId: widget.swapRequestId,
        rating: _rating,
        reviewText: _textCtrl.text.trim().isNotEmpty ? _textCtrl.text.trim() : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.recipientName ?? 'this user';

    return AlertDialog(
      backgroundColor: HomePage.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: HomePage.line),
      ),
      title: Text(
        'Review $name',
        style: const TextStyle(
          color: HomePage.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(color: HomePage.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Center(child: StarSelector(value: _rating, onChanged: (v) => setState(() => _rating = v))),
            const SizedBox(height: 16),
            TextField(
              controller: _textCtrl,
              style: const TextStyle(color: HomePage.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Write a review (optional)',
                hintText: 'Share your experience...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: HomePage.textMuted)),
        ),
        FilledButton(
          onPressed: _submitting || _rating == 0 ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: HomePage.accent,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit Review'),
        ),
      ],
    );
  }
}
