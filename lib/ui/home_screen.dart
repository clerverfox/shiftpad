import 'package:flutter/material.dart';

import '../app_services.dart';
import '../core/click_button.dart';
import '../l10n/app_localizations.dart';
import '../mapping/keymap.dart';
import 'diagnostics_screen.dart';
import 'labels.dart';
import 'mapping_screen.dart';
import 'troubleshooting_screen.dart';
import 'widgets/pod_status_card.dart';
import 'widgets/route_status_card.dart';

enum _MenuItem { mapping, troubleshooting, setup, diagnostics }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.services, required this.onRunSetup});

  final AppServices services;
  final VoidCallback onRunSetup;

  void _open(BuildContext context, _MenuItem item) {
    final Widget? page = switch (item) {
      _MenuItem.mapping => MappingScreen(services: services),
      _MenuItem.troubleshooting => const TroubleshootingScreen(),
      _MenuItem.diagnostics => DiagnosticsScreen(services: services),
      _MenuItem.setup => null,
    };
    if (page == null) {
      onRunSetup();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = services.controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<_MenuItem>(
            onSelected: (item) => _open(context, item),
            itemBuilder: (context) => [
              PopupMenuItem(value: _MenuItem.mapping, child: Text(l10n.menuMapping)),
              PopupMenuItem(
                  value: _MenuItem.troubleshooting, child: Text(l10n.menuTroubleshooting)),
              PopupMenuItem(value: _MenuItem.setup, child: Text(l10n.menuSetup)),
              PopupMenuItem(value: _MenuItem.diagnostics, child: Text(l10n.menuDiagnostics)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ValueListenableBuilder(
            valueListenable: controller.fallbackToRightOnly,
            builder: (context, fallback, _) => fallback
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MaterialBanner(
                      leading: const Icon(Icons.info_outline),
                      content: Text(l10n.fallbackBanner),
                      actions: const [SizedBox.shrink()],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([services.devices.statuses, controller.mode]),
            builder: (context, _) {
              final statuses = services.devices.statuses.value;
              final rightOnly = controller.mode.value == ControlMode.rightOnly;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final side in ClickSide.values)
                    SizedBox(
                      width: 340,
                      child: PodStatusCard(
                        status: statuses[side]!,
                        used: !(rightOnly && side == ClickSide.left),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(width: 692, child: RouteStatusCard(route: services.router.route)),
          const SizedBox(height: 24),
          ValueListenableBuilder(
            valueListenable: controller.lastAction,
            builder: (context, last, _) => Center(
              child: Text(
                last == null
                    ? l10n.nothingPressedYet
                    : l10n.lastPressed(l10n.actionLabel(last.$1), last.$2.inMilliseconds),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
