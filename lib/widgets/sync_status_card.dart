import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card di stato sincronizzazione: ultimo sync, giorni archiviati, record,
/// avviso se i dati sono "stale" (rischio perdita per finestra Health Connect).
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    required this.lastSync,
    required this.archivedDays,
    required this.recordCount,
    required this.isStale,
    required this.isSyncing,
    required this.onSync,
  });

  final DateTime? lastSync;
  final int archivedDays;
  final int recordCount;
  final bool isStale;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastSyncLabel = lastSync == null
        ? 'mai'
        : DateFormat('dd/MM/yyyy HH:mm').format(lastSync!.toLocal());

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Archivio dati',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _row(theme, 'Ultimo sync', lastSyncLabel),
            _row(theme, 'Giorni archiviati', '$archivedDays'),
            _row(theme, 'Record salvati', '$recordCount'),
            if (isStale) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sincronizza per non perdere dati: Health Connect '
                      'conserva solo ~30 giorni.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isSyncing ? null : onSync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(isSyncing ? 'Sincronizzo…' : 'Sincronizza ora'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              )),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
