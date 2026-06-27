import 'package:flutter/material.dart';
import 'package:smooth_charts/smooth_charts.dart';

/// Distribuzione compatta delle sorgenti con donut chart smooth.
class SourcePieChart extends StatelessWidget {
  const SourcePieChart({
    super.key,
    required this.values,
    this.height = 220,
    this.legendBelow = false,
  });

  final Map<String, int> values;
  final double height;
  final bool legendBelow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = values.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();

    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.error,
      theme.colorScheme.outline,
    ];

    final chart = Center(
      child: SmoothPieChart(
        centerColor: theme.cardColor,
        items: [
          for (var i = 0; i < entries.length && i < 5; i++)
            SmoothPieChartItem(
              id: entries[i].key,
              value: entries[i].value.toDouble(),
              color: colors[i % colors.length],
              label: entries[i].key,
              icon: Icon(
                _iconForSource(entries[i].key),
                color: colors[i % colors.length],
                size: 22,
              ),
            ),
        ],
      ),
    );

    if (legendBelow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: height, child: chart),
          const SizedBox(height: 12),
          _Legend(entries: entries, colors: colors),
        ],
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: chart),
          const SizedBox(width: 12),
          Expanded(child: _Legend(entries: entries, colors: colors)),
        ],
      ),
    );
  }

  IconData _iconForSource(String source) {
    final normalized = source.toLowerCase();
    if (normalized.contains('google')) return Icons.fitbit;
    if (normalized.contains('health')) return Icons.health_and_safety_outlined;
    if (normalized.contains('watch')) return Icons.watch_outlined;
    if (normalized.contains('takeout')) return Icons.archive_outlined;
    return Icons.storage_outlined;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries, required this.colors});

  final List<MapEntry<String, int>> entries;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length && i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entries[i].key,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
