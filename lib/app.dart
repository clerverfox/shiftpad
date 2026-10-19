import 'package:flutter/material.dart';

import 'app_services.dart';
import 'l10n/app_localizations.dart';
import 'ui/diagnostics_screen.dart';

class ShiftPadApp extends StatelessWidget {
  const ShiftPadApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: DiagnosticsScreen(services: services),
    );
  }
}
