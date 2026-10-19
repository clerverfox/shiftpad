import 'package:flutter/material.dart';

import '../app_services.dart';
import '../core/click_button.dart';
import '../core/game_action.dart';
import '../l10n/app_localizations.dart';
import '../mapping/keymap.dart';
import 'labels.dart';

/// Lets the rider choose what each button does, per mode.
class MappingScreen extends StatefulWidget {
  const MappingScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  ControlMode? _mode;
  Keymap? _keymap;

  AppServices get _services => widget.services;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([ControlMode? mode]) async {
    final m = mode ?? await _services.settings.mode();
    final k = await _services.settings.keymap(m);
    if (!mounted) return;
    setState(() {
      _mode = m;
      _keymap = k;
    });
  }

  Future<void> _setMode(ControlMode m) async {
    await _services.settings.setMode(m);
    await _services.controller.reloadSettings();
    await _load(m);
  }

  Future<void> _save(Keymap k) async {
    await _services.settings.setKeymap(_mode!, k);
    await _services.controller.reloadSettings();
    if (mounted) setState(() => _keymap = k);
  }

  Future<void> _choose(ClickButton b) async {
    final l10n = AppLocalizations.of(context);
    final picked = await showDialog<GameAction>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.mappingChoose(l10n.buttonLabel(b))),
        children: [
          for (final a in GameAction.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, a),
              child: Text(l10n.actionLabel(a)),
            ),
        ],
      ),
    );
    if (picked != null) await _save(_keymap!.rebind(b, picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mode = _mode;
    final keymap = _keymap;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mappingTitle)),
      body: mode == null || keymap == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.mappingMode, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<ControlMode>(
                  segments: [
                    ButtonSegment(
                        value: ControlMode.rightOnly, label: Text(l10n.modeRightOnly)),
                    ButtonSegment(
                        value: ControlMode.bothPods, label: Text(l10n.modeBothPods)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => _setMode(s.single),
                ),
                for (final side in [ClickSide.right, ClickSide.left])
                  if (side == ClickSide.right || mode == ControlMode.bothPods) ...[
                    const SizedBox(height: 16),
                    Text(l10n.podTitle(side), style: Theme.of(context).textTheme.titleMedium),
                    Card(
                      child: Column(
                        children: [
                          for (final b in ClickButton.values.where((b) => b.side == side))
                            ListTile(
                              title: Text(l10n.buttonLabel(b)),
                              trailing: Text(l10n.actionLabel(keymap.actionFor(b))),
                              onTap: () => _choose(b),
                            ),
                        ],
                      ),
                    ),
                  ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _save(Keymap.defaults(mode)),
                    icon: const Icon(Icons.restore),
                    label: Text(l10n.mappingReset),
                  ),
                ),
              ],
            ),
    );
  }
}
