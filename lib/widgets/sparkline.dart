import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Mini trend senza assi, pensato per stare dentro le card metriche.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 34,
    this.asBars = false,
  });

  final List<double> values;
  final Color color;
  final double height;
  final bool asBars;

  @override
  Widget build(BuildContext context) {
    final cleaned = values.where((v) => v.isFinite && v >= 0).toList();
    if (cleaned.length < 2) return SizedBox(height: height);

    if (asBars) {
      final maxY = cleaned.reduce((a, b) => a > b ? a : b);
      return SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: maxY == 0 ? 1 : maxY * 1.1,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            barTouchData: BarTouchData(enabled: false),
            alignment: BarChartAlignment.spaceBetween,
            barGroups: [
              for (var i = 0; i < cleaned.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: cleaned[i],
                    width: 3,
                    color: color.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ]),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < cleaned.length; i++)
                  FlSpot(i.toDouble(), cleaned[i]),
              ],
              isCurved: true,
              dotData: const FlDotData(show: false),
              barWidth: 2,
              color: color,
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
