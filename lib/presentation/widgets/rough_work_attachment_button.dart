import 'package:flutter/material.dart';

/// Button widget for attaching rough work pages to a note
class RoughWorkAttachmentButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int existingRoughWorkCount;

  const RoughWorkAttachmentButton({
    super.key,
    required this.onPressed,
    this.existingRoughWorkCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(
        existingRoughWorkCount > 0
            ? 'Add More Rough Work'
            : 'Attach Rough Work',
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: theme.colorScheme.secondary,
          width: 1.5,
        ),
      ),
    );
  }
}
