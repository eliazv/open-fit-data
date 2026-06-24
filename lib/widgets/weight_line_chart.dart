import 'package:flutter/material.dart';
import 'package:smooth_charts/smooth_charts.dart';

/// Trend del peso come line chart morbida (smooth_charts).
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({super.key, required this.weights, this.height = 180});

  /// Pesi in ordine cronologico (kg).
  final List<double> weights;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (weights.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Servono almeno 2 misurazioni peso',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ),
      );
    }

    final points = <ChartPair>[
      for (var i = 0; i < weights.length; i++)
        ChartPair(i.toDouble(), weights[i]),
    ];

    return SizedBox(
      height: height,
      child: SmoothLineChart(
        points: [points],
        color: theme.colorScheme.primary,
        isCurved: true,
        yLabelFormatter: (v) => '${v.toStringAsFixed(0)} kg',
      ),
    );
  }
}
