import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'key_injector.dart';

/// Sends scan-code key strokes to the MyWhoosh window with `SendInput`.
///
/// MyWhoosh is an Unreal game, which reads scan codes rather than virtual
/// keys. Keys are only sent while MyWhoosh is the foreground window, so they
/// never end up in another program.
class Win32KeyInjector implements KeyInjector {
  Win32KeyInjector({
    this._exeNames = const {'mywhoosh.exe', 'mywhooshhd.exe'},
    this._onInfo,
    this._focusDelay = const Duration(milliseconds: 200),
  });

  final Set<String> _exeNames;
  final void Function(String message)? _onInfo;

  /// Time the game needs to process its activation before it reads keys.
  final Duration _focusDelay;
  HWND? _window;

  @override
  Future<bool> isTargetRunning() async => _findWindow() != null;

  @override
  Future<bool> keyDown(int virtualKey) => _send(virtualKey, up: false);

  @override
  Future<bool> keyUp(int virtualKey) => _send(virtualKey, up: true);

  Future<bool> _send(int virtualKey, {required bool up}) async {
    final hwnd = _findWindow();
    if (hwnd == null) {
      _onInfo?.call('MyWhoosh window not found');
      return false;
    }
    if (GetForegroundWindow() != hwnd) {
      if (IsIconic(hwnd)) ShowWindow(hwnd, SW_RESTORE);
      SetForegroundWindow(hwnd);
      // Activation is asynchronous: wait for it, then give the game time
      // to process it before it reads keys.
      final deadline = DateTime.now().add(const Duration(milliseconds: 500));
      while (GetForegroundWindow() != hwnd) {
        if (DateTime.now().isAfter(deadline)) {
          _onInfo?.call('could not bring MyWhoosh to the front');
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await Future<void>.delayed(_focusDelay);
    }
    final sent = using((arena) {
      final input = arena<INPUT>();
      input.ref.type = INPUT_KEYBOARD;
      input.ref.ki.wScan = MapVirtualKey(virtualKey, MAPVK_VK_TO_VSC);
      input.ref.ki.dwFlags = up
          ? KEYBD_EVENT_FLAGS(KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP)
          : KEYEVENTF_SCANCODE;
      final result = SendInput(1, input, sizeOf<INPUT>());
      _onInfo?.call('${up ? 'up' : 'down'} vk=0x${virtualKey.toRadixString(16)} '
          'sent=${result.value}');
      if (result.value != 1) {
        _onInfo?.call('SendInput failed, error ${result.error}');
      }
      return result.value == 1;
    });
    return sent;
  }

  HWND? _findWindow() {
    final cached = _window;
    if (cached != null && IsWindow(cached) && _isTarget(cached)) return cached;
    _window = null;

    HWND? found;
    final callback = NativeCallable<WNDENUMPROC>.isolateLocal(
      (Pointer hwnd, int _) {
        final h = HWND(hwnd);
        if (IsWindowVisible(h) && _isTarget(h)) {
          found = h;
          return FALSE;
        }
        return TRUE;
      },
      exceptionalReturn: FALSE,
    );
    try {
      EnumWindows(callback.nativeFunction, const LPARAM(0));
    } finally {
      callback.close();
    }
    return _window = found;
  }

  bool _isTarget(HWND hwnd) {
    final name = _exeOf(hwnd);
    return name != null && _exeNames.contains(name.toLowerCase());
  }

  String? _exeOf(HWND hwnd) => using((arena) {
        final pid = arena<Uint32>();
        GetWindowThreadProcessId(hwnd, pid);
        final process =
            OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid.value)
                .value;
        if (process.address == 0) return null;
        try {
          final size = arena<Uint32>()..value = 1024;
          final buffer = arena<Uint16>(1024).cast<Utf16>();
          if (!QueryFullProcessImageName(
                  process, PROCESS_NAME_WIN32, PWSTR(buffer), size)
              .value) {
            return null;
          }
          return buffer.toDartString(length: size.value).split('\\').last;
        } finally {
          CloseHandle(process);
        }
      });
}
