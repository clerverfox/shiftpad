/// Sends key strokes to the game window. Returns false when it could not.
abstract class KeyInjector {
  Future<bool> isTargetRunning();
  Future<bool> keyDown(int virtualKey);
  Future<bool> keyUp(int virtualKey);
}

/// For platforms without key injection.
class UnsupportedKeyInjector implements KeyInjector {
  const UnsupportedKeyInjector();

  @override
  Future<bool> isTargetRunning() async => false;

  @override
  Future<bool> keyDown(int virtualKey) async => false;

  @override
  Future<bool> keyUp(int virtualKey) async => false;
}
