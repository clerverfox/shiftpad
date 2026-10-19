enum ClickSide { left, right }

enum ClickButton { left, up, right, down, a, b, y, z, minus, plus }

extension ClickButtonInfo on ClickButton {
  /// Bit in the Click V2 buttons bitmap (active-low: bit 0 = pressed).
  int get mask => switch (this) {
        ClickButton.left => 0x1,
        ClickButton.up => 0x2,
        ClickButton.right => 0x4,
        ClickButton.down => 0x8,
        ClickButton.a => 0x10,
        ClickButton.b => 0x20,
        ClickButton.y => 0x40,
        ClickButton.z => 0x80,
        ClickButton.minus => 0x100,
        ClickButton.plus => 0x1000,
      };

  ClickSide get side => switch (this) {
        ClickButton.left ||
        ClickButton.up ||
        ClickButton.right ||
        ClickButton.down ||
        ClickButton.minus =>
          ClickSide.left,
        _ => ClickSide.right,
      };
}

class ButtonEvent {
  const ButtonEvent(this.button, this.pressed, this.at);

  final ClickButton button;
  final bool pressed;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is ButtonEvent &&
      other.button == button &&
      other.pressed == pressed &&
      other.at == at;

  @override
  int get hashCode => Object.hash(button, pressed, at);

  @override
  String toString() =>
      'ButtonEvent(${button.name}, ${pressed ? 'down' : 'up'}, $at)';
}
