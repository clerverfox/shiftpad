import 'package:flutter/material.dart';

import '../app_services.dart';
import '../core/click_button.dart';
import '../core/game_action.dart';
import '../l10n/app_localizations.dart';
import '../mapping/keymap.dart';
import 'widgets/pod_status_card.dart';
import 'widgets/route_status_card.dart';

/// First-launch guide: wake pods, choose mode, connect MyWhoosh, test +.
class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key, required this.services, required this.onDone});

  final AppServices services;
  final VoidCallback onDone;

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  static const _steps = 4;
  int _step = 0;
  ControlMode _mode = ControlMode.bothPods;
  bool _tested = false;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _services.settings.mode().then((m) {
      if (mounted) setState(() => _mode = m);
    });
    _services.controller.lastAction.addListener(_onAction);
  }

  @override
  void dispose() {
    _services.controller.lastAction.removeListener(_onAction);
    super.dispose();
  }

  void _onAction() {
    final last = _services.controller.lastAction.value;
    if (_step == 3 && last?.$1 == GameAction.shiftUp && !_tested) {
      setState(() => _tested = true);
    }
  }

  Future<void> _next() async {
    if (_step == 1) {
      await _services.settings.setMode(_mode);
      await _services.controller.reloadSettings();
    }
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    await _services.settings.setWizardDone(true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (String title, Widget body) = switch (_step) {
      0 => (l10n.wizardWakeTitle, _wake(l10n)),
      1 => (l10n.wizardModeTitle, _modeChoice(l10n)),
      2 => (l10n.wizardConnectTitle, _connect(l10n)),
      _ => (l10n.wizardTestTitle, _test(l10n)),
    };
    final last = _step == _steps - 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              LinearProgressIndicator(value: (_step + 1) / _steps),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              body,
              const SizedBox(height: 32),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: Text(l10n.back),
                    ),
                  const Spacer(),
                  if (last && !_tested)
                    TextButton(onPressed: _next, child: Text(l10n.skip)),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: last && !_tested ? null : _next,
                    child: Text(last ? l10n.finish : l10n.next),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wake(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.wizardWakeBody),
          const SizedBox(height: 16),
          ValueListenableBuilder(
            valueListenable: _services.devices.statuses,
            builder: (context, statuses, _) => Column(
              children: [
                for (final side in ClickSide.values)
                  PodStatusCard(status: statuses[side]!),
              ],
            ),
          ),
        ],
      );

  Widget _modeChoice(AppLocalizations l10n) => RadioGroup<ControlMode>(
        groupValue: _mode,
        onChanged: (m) => setState(() => _mode = m ?? _mode),
        child: Column(
          children: [
            for (final (mode, title, body) in [
              (ControlMode.rightOnly, l10n.wizardModeRightTitle, l10n.wizardModeRightBody),
              (ControlMode.bothPods, l10n.wizardModeBothTitle, l10n.wizardModeBothBody),
            ])
              Card(
                child: RadioListTile<ControlMode>(
                  value: mode,
                  title: Text(title),
                  subtitle: Text(body),
                ),
              ),
          ],
        ),
      );

  Widget _connect(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, text) in [
            l10n.wizardConnectStep1,
            l10n.wizardConnectStep2,
            l10n.wizardConnectStep3,
          ].indexed)
            ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(text),
            ),
          const SizedBox(height: 8),
          RouteStatusCard(route: _services.router.route),
          const SizedBox(height: 8),
          Text(l10n.wizardConnectNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  Widget _test(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.wizardTestBody),
          const SizedBox(height: 24),
          Center(
            child: _tested
                ? Column(children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
                    const SizedBox(height: 8),
                    Text(l10n.wizardTestOk, style: Theme.of(context).textTheme.titleLarge),
                  ])
                : Column(children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(l10n.wizardTestWaiting),
                  ]),
          ),
        ],
      );
}
