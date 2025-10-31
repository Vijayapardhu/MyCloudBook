import 'package:flutter/material.dart';

/// Toggle widget for showing/hiding rough work pages
class RoughWorkToggle extends StatelessWidget {
  final bool showRoughWork;
  final ValueChanged<bool> onChanged;
  final int roughWorkCount;

  const RoughWorkToggle({
    super.key,
    required this.showRoughWork,
    required this.onChanged,
    this.roughWorkCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: showRoughWork
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: showRoughWork
              ? theme.colorScheme.secondary
              : theme.colorScheme.outline.withOpacity(0.2),
          width: showRoughWork ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.scratch_pad,
            size: 20,
            color: showRoughWork
                ? theme.colorScheme.onSecondaryContainer
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rough Work',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: showRoughWork
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (roughWorkCount > 0)
                  Text(
                    '$roughWorkCount page${roughWorkCount > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: showRoughWork
                          ? theme.colorScheme.onSecondaryContainer.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: showRoughWork,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
