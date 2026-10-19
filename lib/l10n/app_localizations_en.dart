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

  @override
  String diagRoute(String route, String app) {
    return 'Output: $route (app: $app)';
  }

  @override
  String get diagNoAction => 'No action yet';

  @override
  String diagLastAction(String action, int ms) {
    return 'Last action: $action, $ms ms';
  }

  @override
  String get diagFallback => 'Right-only fallback on';

  @override
  String get myWhooshFound => 'MyWhoosh window found';

  @override
  String get myWhooshNotFound => 'MyWhoosh window not found';

  @override
  String get sendShiftUp => 'Send shift up in 3 s';

  @override
  String get sendShiftDown => 'Send shift down in 3 s';

  @override
  String get menuMapping => 'Button mapping';

  @override
  String get menuTroubleshooting => 'Troubleshooting';

  @override
  String get menuSetup => 'Run setup again';

  @override
  String get menuDiagnostics => 'Diagnostics';

  @override
  String get podConnected => 'Connected';

  @override
  String get podSearching => 'Searching…';

  @override
  String get podBusy => 'Can\'t connect';

  @override
  String get podBusyHint =>
      'Is Zwift or Zwift Companion open? Close them, then press a button on the controller.';

  @override
  String get podLocked => 'Locked';

  @override
  String get podLockedHint =>
      'The left controller may stop. The right controller covers shifting.';

  @override
  String get podProblem => 'Problem — retrying';

  @override
  String get podSearchingHint =>
      'Press a button on the controller to wake it up.';

  @override
  String get podNotUsed => 'Not used in right-only mode';

  @override
  String battery(int percent) {
    return 'Battery $percent%';
  }

  @override
  String get routeObc => 'Connected to MyWhoosh (OpenBikeControl)';

  @override
  String get routeObcHint => 'Shifts go straight to MyWhoosh.';

  @override
  String get routeKeyboard => 'Keyboard mode';

  @override
  String get routeKeyboardHint =>
      'Shifting works while MyWhoosh is open. For a better link, in MyWhoosh open Connection, choose OpenBikeControl, pick ShiftPad and press Yes.';

  @override
  String get routeNone => 'MyWhoosh not found';

  @override
  String get routeNoneHint => 'Start MyWhoosh on this PC.';

  @override
  String get fallbackBanner =>
      'Left controller locked — using right-only buttons';

  @override
  String lastPressed(String action, int ms) {
    return 'Last: $action · $ms ms';
  }

  @override
  String get nothingPressedYet => 'Press a button to try it.';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get finish => 'Finish';

  @override
  String get wizardWakeTitle => 'Wake your controllers';

  @override
  String get wizardWakeBody =>
      'Close Zwift and Zwift Companion. Then press any button on each Click controller.';

  @override
  String get wizardModeTitle => 'Choose how you ride';

  @override
  String get wizardModeRightTitle => 'Right controller only';

  @override
  String get wizardModeRightBody =>
      '+ shifts up, B shifts down. Simple and always works.';

  @override
  String get wizardModeBothTitle => 'Both controllers';

  @override
  String get wizardModeBothBody =>
      '+ shifts up, − shifts down, arrows steer. If the left controller stops answering, ShiftPad switches to right-only buttons by itself.';

  @override
  String get wizardConnectTitle => 'Connect MyWhoosh';

  @override
  String get wizardConnectStep1 => 'Open MyWhoosh on this PC.';

  @override
  String get wizardConnectStep2 => 'Go to the Connection screen.';

  @override
  String get wizardConnectStep3 =>
      'Choose OpenBikeControl, pick ShiftPad, and press Yes.';

  @override
  String get wizardConnectNote =>
      'If you skip this, ShiftPad uses keyboard mode.';

  @override
  String get wizardTestTitle => 'Press + to test';

  @override
  String get wizardTestBody =>
      'Press + on the right controller. Your gear in MyWhoosh should go up.';

  @override
  String get wizardTestWaiting => 'Waiting for +…';

  @override
  String get wizardTestOk => 'It works!';

  @override
  String get mappingTitle => 'Button mapping';

  @override
  String get mappingMode => 'Mode';

  @override
  String get modeRightOnly => 'Right only';

  @override
  String get modeBothPods => 'Both controllers';

  @override
  String get mappingReset => 'Reset to defaults';

  @override
  String mappingChoose(String button) {
    return 'Choose an action for $button';
  }

  @override
  String get buttonLeft => '← Left';

  @override
  String get buttonUp => '↑ Up';

  @override
  String get buttonRight => '→ Right';

  @override
  String get buttonDown => '↓ Down';

  @override
  String get buttonMinus => '−';

  @override
  String get buttonA => 'A';

  @override
  String get buttonB => 'B';

  @override
  String get buttonY => 'Y';

  @override
  String get buttonZ => 'Z';

  @override
  String get buttonPlus => '+';

  @override
  String get actionNone => 'Nothing';

  @override
  String get actionShiftUp => 'Shift up';

  @override
  String get actionShiftDown => 'Shift down';

  @override
  String get actionSteerLeft => 'Steer left';

  @override
  String get actionSteerRight => 'Steer right';

  @override
  String get actionToggleUi => 'Hide or show the interface';

  @override
  String get actionEmote1 => 'Emote 1';

  @override
  String get actionEmote2 => 'Emote 2';

  @override
  String get actionEmote3 => 'Emote 3';

  @override
  String get actionEmote4 => 'Emote 4';

  @override
  String get troubleTitle => 'Troubleshooting';

  @override
  String get troubleBusyTitle => 'A controller says \"Can\'t connect\"';

  @override
  String get troubleBusyBody =>
      'A Click controller talks to one app at a time. Close Zwift and Zwift Companion (also on your phone). ShiftPad tries again every 5 seconds.';

  @override
  String get troubleLockedTitle => 'The left controller is locked or stopped';

  @override
  String get troubleLockedBody =>
      'ShiftPad switches to right-only buttons by itself: + shifts up, B shifts down. When the left controller answers again, its buttons come back.';

  @override
  String get troubleObcTitle => 'MyWhoosh does not show ShiftPad';

  @override
  String get troubleObcBody =>
      'Keep ShiftPad open. In MyWhoosh open Connection and choose OpenBikeControl. If Windows asks about the firewall, press Allow. MyWhoosh and ShiftPad must be on the same PC or the same network. After ShiftPad restarts, connect again in MyWhoosh.';

  @override
  String get troubleKeyboardTitle => 'Keyboard mode does not shift';

  @override
  String get troubleKeyboardBody =>
      'Keyboard mode needs the MyWhoosh window open (not minimised). ShiftPad brings it to the front when you press a button.';

  @override
  String get troubleLogsTitle => 'Still stuck?';

  @override
  String get troubleLogsBody =>
      'Open Diagnostics from the menu and press Export logs, then send the file.';
}
