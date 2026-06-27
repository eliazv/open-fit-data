import 'package:flutter/material.dart';

import 'metric_type.dart';

/// Visual language condiviso per metriche: icona, colore e unità coerenti.
class MetricStyle {
  const MetricStyle({
    required this.icon,
    required this.color,
    required this.unit,
  });

  final IconData icon;
  final Color color;
  final String unit;
}

extension MetricStyleX on MetricType {
  MetricStyle get style => switch (this) {
        MetricType.steps => const MetricStyle(
            icon: Icons.directions_walk,
            color: Color(0xFF2E7D32),
            unit: 'passi',
          ),
        MetricType.distance => const MetricStyle(
            icon: Icons.straighten,
            color: Color(0xFF0277BD),
            unit: 'km',
          ),
        MetricType.activeCalories => const MetricStyle(
            icon: Icons.local_fire_department,
            color: Color(0xFFE65100),
            unit: 'kcal',
          ),
        MetricType.heartRate => const MetricStyle(
            icon: Icons.favorite,
            color: Color(0xFFC62828),
            unit: 'bpm',
          ),
        MetricType.restingHeartRate => const MetricStyle(
            icon: Icons.favorite_border,
            color: Color(0xFFAD1457),
            unit: 'bpm',
          ),
        MetricType.sleep => const MetricStyle(
            icon: Icons.nightlight_round,
            color: Color(0xFF4527A0),
            unit: 'h',
          ),
        MetricType.weight => const MetricStyle(
            icon: Icons.monitor_weight_outlined,
            color: Color(0xFF6D4C41),
            unit: 'kg',
          ),
        MetricType.speed => const MetricStyle(
            icon: Icons.speed,
            color: Color(0xFF00838F),
            unit: 'km/h',
          ),
        MetricType.vo2max => const MetricStyle(
            icon: Icons.air,
            color: Color(0xFF00695C),
            unit: 'ml/kg/min',
          ),
        MetricType.hrv => const MetricStyle(
            icon: Icons.monitor_heart_outlined,
            color: Color(0xFF8E24AA),
            unit: 'ms',
          ),
      };
}
