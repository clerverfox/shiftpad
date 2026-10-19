import 'package:flutter/material.dart' hide LockState;

import '../../l10n/app_localizations.dart';
import '../../zwift/click_session.dart';
import '../labels.dart';

enum PodDisplay { connected, searching, busy, locked, problem, notUsed }

PodDisplay podDisplayFor(ClickStatus s, {bool used = true}) {
  if (!used) return PodDisplay.notUsed;
  return switch (s.link) {
    LinkState.ready =>
      s.lock == LockState.locked ? PodDisplay.locked : PodDisplay.connected,
    LinkState.busyElsewhere => PodDisplay.busy,
    LinkState.error => PodDisplay.problem,
    LinkState.disconnected ||
    LinkState.connecting ||
    LinkState.handshaking =>
      PodDisplay.searching,
  };
}

class PodStatusCard extends StatelessWidget {
  const PodStatusCard({super.key, required this.status, this.used = true});

  final ClickStatus status;

  /// False for the left pod in right-only mode.
  final bool used;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final display = podDisplayFor(status, used: used);
    final (IconData icon, Color color, String label, String? hint) = switch (display) {
      PodDisplay.connected => (Icons.check_circle, Colors.green.shade600, l10n.podConnected, null),
      PodDisplay.searching => (Icons.bluetooth_searching, scheme.primary, l10n.podSearching, l10n.podSearchingHint),
      PodDisplay.busy => (Icons.block, scheme.error, l10n.podBusy, l10n.podBusyHint),
      PodDisplay.locked => (Icons.touch_app, Colors.orange.shade700, l10n.podLocked, l10n.podLockedHint),
      PodDisplay.problem => (Icons.error_outline, scheme.error, l10n.podProblem, null),
      PodDisplay.notUsed => (Icons.remove_circle_outline, scheme.outline, l10n.podNotUsed, null),
    };
    final battery = status.batteryPercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.podTitle(status.side),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  if (hint != null) ...[
                    const SizedBox(height: 4),
                    Text(hint, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (battery != null && display == PodDisplay.connected) ...[
                    const SizedBox(height: 4),
                    Text(l10n.battery(battery), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
