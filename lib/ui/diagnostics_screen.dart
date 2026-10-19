import 'package:flutter/material.dart';

import '../app_services.dart';
import '../core/click_button.dart';
import '../core/game_action.dart';
import '../diagnostics/app_log.dart';
import '../l10n/app_localizations.dart';
import '../zwift/click_session.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diagnosticsTitle),
        actions: [
          TextButton.icon(
            onPressed: () => _export(context),
            icon: const Icon(Icons.save_alt),
            label: Text(l10n.exportLogs),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder(
            valueListenable: services.devices.statuses,
            builder: (context, statuses, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final side in ClickSide.values)
                    _PodDiagnosticsCard(status: statuses[side]!),
                ],
              ),
            ),
          ),
          _KeyboardTestRow(services: services),
          const Divider(height: 1),
          Expanded(child: _LogView(log: services.log)),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await services.log.export();
      messenger.showSnackBar(SnackBar(content: Text(l10n.logsSaved(file.path))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.logsSaveFailed('$e'))));
    }
  }
}

class _PodDiagnosticsCard extends StatelessWidget {
  const _PodDiagnosticsCard({required this.status});

  final ClickStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dash = l10n.notAvailable;
    final rows = <(String, String)>[
      (l10n.diagLink, status.link.name),
      (l10n.diagLock, status.lock.name),
      (l10n.diagBattery,
          status.batteryPercent == null ? dash : '${status.batteryPercent}%'),
      (l10n.diagFirmware, status.firmware ?? dash),
      (l10n.diagLastFrame,
          status.lastFrameAt == null ? dash : _time(status.lastFrameAt!)),
      if (status.error != null) (l10n.diagError, status.error!),
    ];
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.side == ClickSide.left ? l10n.leftPod : l10n.rightPod,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final (label, value) in rows)
                Text('$label: $value', key: ValueKey('${status.side.name}-$label')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug buttons to check key injection into MyWhoosh by hand.
class _KeyboardTestRow extends StatelessWidget {
  const _KeyboardTestRow({required this.services});

  final AppServices services;

  Future<void> _tap(GameAction action) async {
    final router = services.router;
    // Gives time to click into MyWhoosh, like during a real ride.
    await Future<void>.delayed(const Duration(seconds: 3));
    final route = await router.send(action, pressed: true);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await router.send(action, pressed: false);
    services.log.info('test', '${action.name} via ${route.name}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ValueListenableBuilder(
            valueListenable: services.keyboard.available,
            builder: (context, found, _) =>
                Text(found ? l10n.myWhooshFound : l10n.myWhooshNotFound),
          ),
          OutlinedButton(
            onPressed: () => _tap(GameAction.shiftUp),
            child: Text(l10n.sendShiftUp),
          ),
          OutlinedButton(
            onPressed: () => _tap(GameAction.shiftDown),
            child: Text(l10n.sendShiftDown),
          ),
        ],
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView({required this.log});

  final AppLog log;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LogLine>(
      stream: log.stream,
      builder: (context, _) {
        final lines = log.lines;
        return ListView.builder(
          reverse: true,
          itemCount: lines.length,
          itemBuilder: (context, i) {
            final line = lines[lines.length - 1 - i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              child: Text(
                '${_time(line.at)} [${line.tag}] ${line.text}',
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }
}

String _time(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
      '${t.millisecond.toString().padLeft(3, '0')}';
}
