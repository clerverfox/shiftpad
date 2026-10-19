import '../core/click_button.dart';

/// Turns successive "pressed buttons" snapshots into press/release events.
///
/// Duplicate snapshots produce nothing. Releases come before presses, each
/// group in [ClickButton.values] order.
class ButtonDiffer {
  Set<ClickButton> _previous = const {};

  List<ButtonEvent> update(Set<ClickButton> pressed, DateTime at) {
    final events = <ButtonEvent>[
      for (final b in ClickButton.values)
        if (_previous.contains(b) && !pressed.contains(b))
          ButtonEvent(b, false, at),
      for (final b in ClickButton.values)
        if (!_previous.contains(b) && pressed.contains(b))
          ButtonEvent(b, true, at),
    ];
    _previous = Set.unmodifiable(pressed);
    return events;
  }

  void reset() => _previous = const {};
}
