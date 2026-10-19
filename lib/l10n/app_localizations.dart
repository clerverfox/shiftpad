import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShiftPad'**
  String get appTitle;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get exportLogs;

  /// No description provided for @logsSaved.
  ///
  /// In en, this message translates to:
  /// **'Logs saved to {path}'**
  String logsSaved(String path);

  /// No description provided for @logsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save logs: {error}'**
  String logsSaveFailed(String error);

  /// No description provided for @leftPod.
  ///
  /// In en, this message translates to:
  /// **'Left controller'**
  String get leftPod;

  /// No description provided for @rightPod.
  ///
  /// In en, this message translates to:
  /// **'Right controller'**
  String get rightPod;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get notAvailable;

  /// No description provided for @diagLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get diagLink;

  /// No description provided for @diagLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get diagLock;

  /// No description provided for @diagBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get diagBattery;

  /// No description provided for @diagFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get diagFirmware;

  /// No description provided for @diagLastFrame.
  ///
  /// In en, this message translates to:
  /// **'Last frame'**
  String get diagLastFrame;

  /// No description provided for @diagError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get diagError;

  /// No description provided for @diagRoute.
  ///
  /// In en, this message translates to:
  /// **'Output: {route} (app: {app})'**
  String diagRoute(String route, String app);

  /// No description provided for @diagNoAction.
  ///
  /// In en, this message translates to:
  /// **'No action yet'**
  String get diagNoAction;

  /// No description provided for @diagLastAction.
  ///
  /// In en, this message translates to:
  /// **'Last action: {action}, {ms} ms'**
  String diagLastAction(String action, int ms);

  /// No description provided for @diagFallback.
  ///
  /// In en, this message translates to:
  /// **'Right-only fallback on'**
  String get diagFallback;

  /// No description provided for @myWhooshFound.
  ///
  /// In en, this message translates to:
  /// **'MyWhoosh window found'**
  String get myWhooshFound;

  /// No description provided for @myWhooshNotFound.
  ///
  /// In en, this message translates to:
  /// **'MyWhoosh window not found'**
  String get myWhooshNotFound;

  /// No description provided for @sendShiftUp.
  ///
  /// In en, this message translates to:
  /// **'Send shift up in 3 s'**
  String get sendShiftUp;

  /// No description provided for @sendShiftDown.
  ///
  /// In en, this message translates to:
  /// **'Send shift down in 3 s'**
  String get sendShiftDown;

  /// No description provided for @menuMapping.
  ///
  /// In en, this message translates to:
  /// **'Button mapping'**
  String get menuMapping;

  /// No description provided for @menuTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get menuTroubleshooting;

  /// No description provided for @menuSetup.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get menuSetup;

  /// No description provided for @menuDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get menuDiagnostics;

  /// No description provided for @podConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get podConnected;

  /// No description provided for @podSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get podSearching;

  /// No description provided for @podBusy.
  ///
  /// In en, this message translates to:
  /// **'Used by another app'**
  String get podBusy;

  /// No description provided for @podBusyHint.
  ///
  /// In en, this message translates to:
  /// **'Close Zwift and Zwift Companion, then wait a few seconds.'**
  String get podBusyHint;

  /// No description provided for @podLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get podLocked;

  /// No description provided for @podLockedHint.
  ///
  /// In en, this message translates to:
  /// **'The left controller may stop. The right controller covers shifting.'**
  String get podLockedHint;

  /// No description provided for @podProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem — retrying'**
  String get podProblem;

  /// No description provided for @podSearchingHint.
  ///
  /// In en, this message translates to:
  /// **'Press a button on the controller to wake it up.'**
  String get podSearchingHint;

  /// No description provided for @podNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used in right-only mode'**
  String get podNotUsed;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery {percent}%'**
  String battery(int percent);

  /// No description provided for @routeObc.
  ///
  /// In en, this message translates to:
  /// **'Connected to MyWhoosh (OpenBikeControl)'**
  String get routeObc;

  /// No description provided for @routeObcHint.
  ///
  /// In en, this message translates to:
  /// **'Shifts go straight to MyWhoosh.'**
  String get routeObcHint;

  /// No description provided for @routeKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard mode'**
  String get routeKeyboard;

  /// No description provided for @routeKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Shifting works while MyWhoosh is open. For a better link, in MyWhoosh open Connection, choose OpenBikeControl, pick ShiftPad and press Yes.'**
  String get routeKeyboardHint;

  /// No description provided for @routeNone.
  ///
  /// In en, this message translates to:
  /// **'MyWhoosh not found'**
  String get routeNone;

  /// No description provided for @routeNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Start MyWhoosh on this PC.'**
  String get routeNoneHint;

  /// No description provided for @fallbackBanner.
  ///
  /// In en, this message translates to:
  /// **'Left controller locked — using right-only buttons'**
  String get fallbackBanner;

  /// No description provided for @lastPressed.
  ///
  /// In en, this message translates to:
  /// **'Last: {action} · {ms} ms'**
  String lastPressed(String action, int ms);

  /// No description provided for @nothingPressedYet.
  ///
  /// In en, this message translates to:
  /// **'Press a button to try it.'**
  String get nothingPressedYet;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @wizardWakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wake your controllers'**
  String get wizardWakeTitle;

  /// No description provided for @wizardWakeBody.
  ///
  /// In en, this message translates to:
  /// **'Close Zwift and Zwift Companion. Then press any button on each Click controller.'**
  String get wizardWakeBody;

  /// No description provided for @wizardModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you ride'**
  String get wizardModeTitle;

  /// No description provided for @wizardModeRightTitle.
  ///
  /// In en, this message translates to:
  /// **'Right controller only'**
  String get wizardModeRightTitle;

  /// No description provided for @wizardModeRightBody.
  ///
  /// In en, this message translates to:
  /// **'+ shifts up, B shifts down. Simple and always works.'**
  String get wizardModeRightBody;

  /// No description provided for @wizardModeBothTitle.
  ///
  /// In en, this message translates to:
  /// **'Both controllers'**
  String get wizardModeBothTitle;

  /// No description provided for @wizardModeBothBody.
  ///
  /// In en, this message translates to:
  /// **'+ shifts up, − shifts down, arrows steer. If the left controller stops answering, ShiftPad switches to right-only buttons by itself.'**
  String get wizardModeBothBody;

  /// No description provided for @wizardConnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect MyWhoosh'**
  String get wizardConnectTitle;

  /// No description provided for @wizardConnectStep1.
  ///
  /// In en, this message translates to:
  /// **'Open MyWhoosh on this PC.'**
  String get wizardConnectStep1;

  /// No description provided for @wizardConnectStep2.
  ///
  /// In en, this message translates to:
  /// **'Go to the Connection screen.'**
  String get wizardConnectStep2;

  /// No description provided for @wizardConnectStep3.
  ///
  /// In en, this message translates to:
  /// **'Choose OpenBikeControl, pick ShiftPad, and press Yes.'**
  String get wizardConnectStep3;

  /// No description provided for @wizardConnectNote.
  ///
  /// In en, this message translates to:
  /// **'If you skip this, ShiftPad uses keyboard mode.'**
  String get wizardConnectNote;

  /// No description provided for @wizardTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Press + to test'**
  String get wizardTestTitle;

  /// No description provided for @wizardTestBody.
  ///
  /// In en, this message translates to:
  /// **'Press + on the right controller. Your gear in MyWhoosh should go up.'**
  String get wizardTestBody;

  /// No description provided for @wizardTestWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for +…'**
  String get wizardTestWaiting;

  /// No description provided for @wizardTestOk.
  ///
  /// In en, this message translates to:
  /// **'It works!'**
  String get wizardTestOk;

  /// No description provided for @mappingTitle.
  ///
  /// In en, this message translates to:
  /// **'Button mapping'**
  String get mappingTitle;

  /// No description provided for @mappingMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mappingMode;

  /// No description provided for @modeRightOnly.
  ///
  /// In en, this message translates to:
  /// **'Right only'**
  String get modeRightOnly;

  /// No description provided for @modeBothPods.
  ///
  /// In en, this message translates to:
  /// **'Both controllers'**
  String get modeBothPods;

  /// No description provided for @mappingReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get mappingReset;

  /// No description provided for @mappingChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose an action for {button}'**
  String mappingChoose(String button);

  /// No description provided for @buttonLeft.
  ///
  /// In en, this message translates to:
  /// **'← Left'**
  String get buttonLeft;

  /// No description provided for @buttonUp.
  ///
  /// In en, this message translates to:
  /// **'↑ Up'**
  String get buttonUp;

  /// No description provided for @buttonRight.
  ///
  /// In en, this message translates to:
  /// **'→ Right'**
  String get buttonRight;

  /// No description provided for @buttonDown.
  ///
  /// In en, this message translates to:
  /// **'↓ Down'**
  String get buttonDown;

  /// No description provided for @buttonMinus.
  ///
  /// In en, this message translates to:
  /// **'−'**
  String get buttonMinus;

  /// No description provided for @buttonA.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get buttonA;

  /// No description provided for @buttonB.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get buttonB;

  /// No description provided for @buttonY.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get buttonY;

  /// No description provided for @buttonZ.
  ///
  /// In en, this message translates to:
  /// **'Z'**
  String get buttonZ;

  /// No description provided for @buttonPlus.
  ///
  /// In en, this message translates to:
  /// **'+'**
  String get buttonPlus;

  /// No description provided for @actionNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get actionNone;

  /// No description provided for @actionShiftUp.
  ///
  /// In en, this message translates to:
  /// **'Shift up'**
  String get actionShiftUp;

  /// No description provided for @actionShiftDown.
  ///
  /// In en, this message translates to:
  /// **'Shift down'**
  String get actionShiftDown;

  /// No description provided for @actionSteerLeft.
  ///
  /// In en, this message translates to:
  /// **'Steer left'**
  String get actionSteerLeft;

  /// No description provided for @actionSteerRight.
  ///
  /// In en, this message translates to:
  /// **'Steer right'**
  String get actionSteerRight;

  /// No description provided for @actionToggleUi.
  ///
  /// In en, this message translates to:
  /// **'Hide or show the interface'**
  String get actionToggleUi;

  /// No description provided for @actionEmote1.
  ///
  /// In en, this message translates to:
  /// **'Emote 1'**
  String get actionEmote1;

  /// No description provided for @actionEmote2.
  ///
  /// In en, this message translates to:
  /// **'Emote 2'**
  String get actionEmote2;

  /// No description provided for @actionEmote3.
  ///
  /// In en, this message translates to:
  /// **'Emote 3'**
  String get actionEmote3;

  /// No description provided for @actionEmote4.
  ///
  /// In en, this message translates to:
  /// **'Emote 4'**
  String get actionEmote4;

  /// No description provided for @troubleTitle.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get troubleTitle;

  /// No description provided for @troubleBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'A controller says \"Used by another app\"'**
  String get troubleBusyTitle;

  /// No description provided for @troubleBusyBody.
  ///
  /// In en, this message translates to:
  /// **'A Click controller talks to one app at a time. Close Zwift and Zwift Companion (also on your phone). ShiftPad tries again every 5 seconds.'**
  String get troubleBusyBody;

  /// No description provided for @troubleLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'The left controller is locked or stopped'**
  String get troubleLockedTitle;

  /// No description provided for @troubleLockedBody.
  ///
  /// In en, this message translates to:
  /// **'ShiftPad switches to right-only buttons by itself: + shifts up, B shifts down. When the left controller answers again, its buttons come back.'**
  String get troubleLockedBody;

  /// No description provided for @troubleObcTitle.
  ///
  /// In en, this message translates to:
  /// **'MyWhoosh does not show ShiftPad'**
  String get troubleObcTitle;

  /// No description provided for @troubleObcBody.
  ///
  /// In en, this message translates to:
  /// **'Keep ShiftPad open. In MyWhoosh open Connection and choose OpenBikeControl. If Windows asks about the firewall, press Allow. MyWhoosh and ShiftPad must be on the same PC or the same network. After ShiftPad restarts, connect again in MyWhoosh.'**
  String get troubleObcBody;

  /// No description provided for @troubleKeyboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard mode does not shift'**
  String get troubleKeyboardTitle;

  /// No description provided for @troubleKeyboardBody.
  ///
  /// In en, this message translates to:
  /// **'Keyboard mode needs the MyWhoosh window open (not minimised). ShiftPad brings it to the front when you press a button.'**
  String get troubleKeyboardBody;

  /// No description provided for @troubleLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Still stuck?'**
  String get troubleLogsTitle;

  /// No description provided for @troubleLogsBody.
  ///
  /// In en, this message translates to:
  /// **'Open Diagnostics from the menu and press Export logs, then send the file.'**
  String get troubleLogsBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
