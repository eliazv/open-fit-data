import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/period.dart';
import '../../data/db/database.dart';

/// Periodo selezionato nella schermata Archivio.
final archivePeriodProvider = StateProvider<Period>((_) => Period.d7);

/// Riepiloghi giornalieri per il periodo selezionato.
final archiveSummariesProvider =
    FutureProvider<List<DailySummary>>((ref) async {
  final period = ref.watch(archivePeriodProvider);
  final repo = ref.watch(archiveRepositoryProvider);

  if (period.days == null) return repo.allSummaries();

  final fmt = DateFormat('yyyy-MM-dd');
  final now = DateTime.now();
  final from = fmt.format(now.subtract(Duration(days: period.days! - 1)));
  final to = fmt.format(now);
  return repo.summariesInRange(from, to);
});
