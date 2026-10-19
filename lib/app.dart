import 'package:flutter/material.dart';

import 'app_services.dart';
import 'l10n/app_localizations.dart';
import 'ui/home_screen.dart';
import 'ui/setup_wizard.dart';

class ShiftPadApp extends StatefulWidget {
  const ShiftPadApp({super.key, required this.services});

  final AppServices services;

  @override
  State<ShiftPadApp> createState() => _ShiftPadAppState();
}

class _ShiftPadAppState extends State<ShiftPadApp> {
  bool? _wizardDone;

  @override
  void initState() {
    super.initState();
    widget.services.settings.wizardDone().then((done) {
      if (mounted) setState(() => _wizardDone = done);
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      home: switch (_wizardDone) {
        null => const Scaffold(body: Center(child: CircularProgressIndicator())),
        false => SetupWizard(
            services: services,
            onDone: () => setState(() => _wizardDone = true),
          ),
        true => HomeScreen(
            services: services,
            onRunSetup: () => setState(() => _wizardDone = false),
          ),
      },
    );
  }
}
