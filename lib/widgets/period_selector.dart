import 'package:flutter/material.dart';

import '../core/period.dart';

/// Selettore segmentato Material 3 per il periodo.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Period selected;
  final ValueChanged<Period> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Period>(
      showSelectedIcon: false,
      segments: [
        for (final p in Period.values)
          ButtonSegment(value: p, label: Text(p.label)),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
