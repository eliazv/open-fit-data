import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Grafico a barre minimale per i trend (poco rumore, niente assi pesanti).
class BarTrendChart extends StatelessWidget {
  const BarTrendChart({super.key, required this.values, this.height = 160});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('Nessun dato',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ),
      );
    }

    final maxY = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY * 1.15,
          alignment: BarChartAlignment.spaceBetween,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                rod.toY.round().toString(),
                TextStyle(color: theme.colorScheme.onInverseSurface),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: values.length > 45 ? 3 : 6,
                    borderRadius: BorderRadius.circular(3),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
