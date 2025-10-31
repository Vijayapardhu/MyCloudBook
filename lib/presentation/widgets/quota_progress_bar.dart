import 'package:flutter/material.dart';

/// Quota progress bar widget
class QuotaProgressBar extends StatelessWidget {
  final String label;
  final int used;
  final int? limit;
  final double percentage;
  final Color color;
  final String unit;

  const QuotaProgressBar({
    super.key,
    required this.label,
    required this.used,
    this.limit,
    required this.percentage,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final displayLimit = limit != null ? '$limit $unit' : 'Unlimited';
    final displayUsed = '$used $unit';

    Color progressColor = color;
    if (percentage >= 1.0) {
      progressColor = Colors.red;
    } else if (percentage >= 0.8) {
      progressColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  limit != null ? '$displayUsed / $displayLimit' : displayUsed,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            if (limit != null)
              Text(
                '${((percentage * 100).clamp(0.0, 100.0)).toStringAsFixed(1)}% used',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

