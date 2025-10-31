import 'package:flutter/material.dart';

/// Widget that displays a continuation arrow between consecutive daily notes
class ContinuationArrow extends StatelessWidget {
  final bool isVisible;
  final bool isAnimating;

  const ContinuationArrow({
    super.key,
    this.isVisible = true,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_downward,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
