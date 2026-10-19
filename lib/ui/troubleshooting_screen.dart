import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = [
      (Icons.block, l10n.troubleBusyTitle, l10n.troubleBusyBody),
      (Icons.lock, l10n.troubleLockedTitle, l10n.troubleLockedBody),
      (Icons.link_off, l10n.troubleObcTitle, l10n.troubleObcBody),
      (Icons.keyboard, l10n.troubleKeyboardTitle, l10n.troubleKeyboardBody),
      (Icons.description, l10n.troubleLogsTitle, l10n.troubleLogsBody),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.troubleTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (icon, title, body) in entries)
            Card(
              child: ExpansionTile(
                leading: Icon(icon),
                title: Text(title),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [Text(body)],
              ),
            ),
        ],
      ),
    );
  }
}
