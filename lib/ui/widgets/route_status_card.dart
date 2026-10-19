import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../output/output_router.dart';

class RouteStatusCard extends StatelessWidget {
  const RouteStatusCard({super.key, required this.route});

  final ValueListenable<OutputRoute> route;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: route,
      builder: (context, r, _) {
        final (IconData icon, Color color, String title, String hint) = switch (r) {
          OutputRoute.openBikeControl =>
            (Icons.link, Colors.green.shade600, l10n.routeObc, l10n.routeObcHint),
          OutputRoute.keyboard =>
            (Icons.keyboard, scheme.primary, l10n.routeKeyboard, l10n.routeKeyboardHint),
          OutputRoute.none =>
            (Icons.link_off, scheme.error, l10n.routeNone, l10n.routeNoneHint),
        };
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
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: color)),
                      const SizedBox(height: 4),
                      Text(hint, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
