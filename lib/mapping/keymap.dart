import '../core/click_button.dart';
import '../core/game_action.dart';

enum ControlMode { rightOnly, bothPods }

/// Which [GameAction] each [ClickButton] triggers.
class Keymap {
  const Keymap(this.bindings);

  final Map<ClickButton, GameAction> bindings;

  GameAction actionFor(ClickButton b) => bindings[b] ?? GameAction.none;

  Keymap rebind(ClickButton b, GameAction a) => Keymap({...bindings, b: a});

  static Keymap defaults(ControlMode m) => switch (m) {
        ControlMode.rightOnly => const Keymap({
            ClickButton.plus: GameAction.shiftUp,
            ClickButton.b: GameAction.shiftDown,
            ClickButton.a: GameAction.toggleUi,
            ClickButton.y: GameAction.emote1,
            ClickButton.z: GameAction.emote2,
          }),
        ControlMode.bothPods => const Keymap({
            ClickButton.plus: GameAction.shiftUp,
            ClickButton.minus: GameAction.shiftDown,
            ClickButton.left: GameAction.steerLeft,
            ClickButton.right: GameAction.steerRight,
            ClickButton.up: GameAction.emote1,
            ClickButton.down: GameAction.emote2,
            ClickButton.a: GameAction.toggleUi,
            ClickButton.b: GameAction.emote3,
            ClickButton.y: GameAction.emote4,
          }),
      };

  Map<String, String> toJson() => {
        for (final b in ClickButton.values) b.name: actionFor(b).name,
      };

  /// Unknown names are ignored, so old or hand-edited settings never crash.
  factory Keymap.fromJson(Map<String, dynamic> json) => Keymap({
        for (final MapEntry(:key, :value) in json.entries)
          ?ClickButton.values.asNameMap()[key]:
              ?GameAction.values.asNameMap()['$value'],
      });

  @override
  bool operator ==(Object other) =>
      other is Keymap &&
      ClickButton.values.every((b) => actionFor(b) == other.actionFor(b));

  @override
  int get hashCode => Object.hashAll(ClickButton.values.map(actionFor));
}
