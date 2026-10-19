import 'package:flutter/foundation.dart';

import '../core/game_action.dart';

/// A way to deliver [GameAction]s to the game.
abstract class GameOutput {
  Future<void> start();
  Future<void> stop();

  /// True while actions sent here can reach the game.
  ValueListenable<bool> get available;

  /// Whether this output has a way to express [action].
  bool supports(GameAction action);

  Future<void> send(GameAction action, {required bool pressed});
}
