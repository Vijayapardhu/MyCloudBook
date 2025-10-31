import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget that displays a date header for grouping notes in timeline
class DateGroupHeader extends StatelessWidget {
  final DateTime date;
  final int noteCount;
  final bool showContinuation;

  const DateGroupHeader({
    super.key,
    required this.date,
    this.noteCount = 0,
    this.showContinuation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String displayText;
    Color? backgroundColor;
    Color? textColor;
    
    if (isToday) {
      displayText = 'Today';
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (isYesterday) {
      displayText = 'Yesterday';
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
    } else {
      displayText = _formatDate(date);
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          if (showContinuation) ...[
            Icon(
              Icons.arrow_downward,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (noteCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: textColor?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$noteCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yearDiff = now.year - date.year;
    
    if (yearDiff == 0) {
      // Same year - show month and day
      return DateFormat('MMMM d').format(date);
    } else {
      // Different year - show full date
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}
