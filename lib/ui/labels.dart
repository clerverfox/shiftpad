import '../core/click_button.dart';
import '../core/game_action.dart';
import '../l10n/app_localizations.dart';

extension ShiftPadLabels on AppLocalizations {
  String buttonLabel(ClickButton b) => switch (b) {
        ClickButton.left => buttonLeft,
        ClickButton.up => buttonUp,
        ClickButton.right => buttonRight,
        ClickButton.down => buttonDown,
        ClickButton.minus => buttonMinus,
        ClickButton.a => buttonA,
        ClickButton.b => buttonB,
        ClickButton.y => buttonY,
        ClickButton.z => buttonZ,
        ClickButton.plus => buttonPlus,
      };

  String actionLabel(GameAction a) => switch (a) {
        GameAction.none => actionNone,
        GameAction.shiftUp => actionShiftUp,
        GameAction.shiftDown => actionShiftDown,
        GameAction.steerLeft => actionSteerLeft,
        GameAction.steerRight => actionSteerRight,
        GameAction.toggleUi => actionToggleUi,
        GameAction.emote1 => actionEmote1,
        GameAction.emote2 => actionEmote2,
        GameAction.emote3 => actionEmote3,
        GameAction.emote4 => actionEmote4,
      };

  String podTitle(ClickSide side) => side == ClickSide.left ? leftPod : rightPod;
}
