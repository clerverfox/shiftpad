// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShiftPad';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get exportLogs => 'Export logs';

  @override
  String logsSaved(String path) {
    return 'Logs saved to $path';
  }

  @override
  String logsSaveFailed(String error) {
    return 'Could not save logs: $error';
  }

  @override
  String get leftPod => 'Left controller';

  @override
  String get rightPod => 'Right controller';

  @override
  String get notAvailable => '—';

  @override
  String get diagLink => 'Link';

  @override
  String get diagLock => 'Lock';

  @override
  String get diagBattery => 'Battery';

  @override
  String get diagFirmware => 'Firmware';

  @override
  String get diagLastFrame => 'Last frame';

  @override
  String get diagError => 'Error';
}
