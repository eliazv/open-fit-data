import 'package:flutter/material.dart';

import 'sparkline.dart';

/// Card metrica del design system: numero grande, delta e mini trend.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.trendValues = const [],
    this.deltaPercent,
    this.trendAsBars = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final List<double> trendValues;
  final double? deltaPercent;
  final bool trendAsBars;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final delta = deltaPercent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null || delta != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (delta != null) _DeltaBadge(deltaPercent: delta),
                ],
              ),
            ],
            if (trendValues.length >= 2) ...[
              const Spacer(),
              Sparkline(
                values: trendValues,
                color: accent,
                asBars: trendAsBars,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.deltaPercent});

  final double deltaPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = deltaPercent >= 0;
    final color = isUp ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${isUp ? '+' : ''}${deltaPercent.toStringAsFixed(0)}%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
