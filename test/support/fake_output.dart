import 'package:flutter/foundation.dart';
import 'package:shiftpad/core/game_action.dart';
import 'package:shiftpad/output/game_output.dart';

class FakeOutput implements GameOutput {
  FakeOutput({bool available = false, this.unsupported = const {}})
      : availableNotifier = ValueNotifier(available);

  final ValueNotifier<bool> availableNotifier;
  final Set<GameAction> unsupported;
  final sent = <(GameAction, bool)>[];

  @override
  ValueListenable<bool> get available => availableNotifier;

  @override
  bool supports(GameAction action) => !unsupported.contains(action);

  @override
  Future<void> send(GameAction action, {required bool pressed}) async =>
      sent.add((action, pressed));

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
