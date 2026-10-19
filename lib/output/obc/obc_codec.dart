import 'dart:convert';
import 'dart:typed_data';

import '../../core/game_action.dart';

/// OpenBikeControl protocol facts (github.com/OpenBikeControl/openbikecontrol-protocol, MIT).
const kObcServiceType = '_openbikecontrol._tcp';
const kObcBleServiceUuid = 'd273f680-d548-419d-b9d1-fa0472345229';

const kObcMsgButtons = 0x01;
const kObcMsgStatus = 0x02;
const kObcMsgHaptic = 0x03;
const kObcMsgAppInfo = 0x04;

/// Standard OpenBikeControl button id for [a], or null if it has none.
int? obcButtonId(GameAction a) => switch (a) {
      GameAction.shiftUp => 0x01,
      GameAction.shiftDown => 0x02,
      GameAction.steerLeft => 0x18,
      GameAction.steerRight => 0x19,
      GameAction.toggleUi => 0x44, // HUD toggle
      GameAction.emote1 => 0x20, // emote, "pressed" cycles through emotes
      GameAction.emote2 ||
      GameAction.emote3 ||
      GameAction.emote4 ||
      GameAction.none =>
        null,
    };

Uint8List encodeObcButton(int buttonId, bool pressed) =>
    Uint8List.fromList([kObcMsgButtons, buttonId, pressed ? 1 : 0]);

/// Device status: battery unknown (0xFF), connected and ready.
Uint8List encodeObcStatus({int battery = 0xFF, bool ready = true}) =>
    Uint8List.fromList([kObcMsgStatus, battery, ready ? 1 : 0]);

class ObcAppInfo {
  const ObcAppInfo(this.appId, this.appVersion, this.buttonIds);
  final String appId;
  final String appVersion;

  /// Empty means the app supports every button.
  final List<int> buttonIds;
}

/// Splits the byte stream an app sends into messages.
class ObcAppMessageReader {
  final _buffer = BytesBuilder(copy: false);

  /// Feeds [chunk]; returns the complete app-info messages found. Haptic
  /// messages are consumed and ignored. Unknown data resets the buffer.
  List<ObcAppInfo> add(List<int> chunk) {
    _buffer.add(chunk);
    var bytes = _buffer.takeBytes();
    final out = <ObcAppInfo>[];
    var i = 0;
    while (i < bytes.length) {
      final type = bytes[i];
      if (type == kObcMsgHaptic) {
        if (bytes.length - i < 4) break;
        i += 4;
      } else if (type == kObcMsgAppInfo) {
        final parsed = _readAppInfo(bytes, i);
        if (parsed == null) break; // incomplete, wait for more
        out.add(parsed.$1);
        i = parsed.$2;
      } else {
        i = bytes.length; // cannot resync on an unknown type
      }
    }
    if (i < bytes.length) _buffer.add(Uint8List.sublistView(bytes, i));
    return out;
  }

  static (ObcAppInfo, int)? _readAppInfo(Uint8List b, int start) {
    var i = start + 2; // type, format version
    if (i >= b.length) return null;
    final idLen = b[i++];
    if (i + idLen >= b.length) return null;
    final id = utf8.decode(b.sublist(i, i + idLen), allowMalformed: true);
    i += idLen;
    final verLen = b[i++];
    if (i + verLen >= b.length) return null;
    final version = utf8.decode(b.sublist(i, i + verLen), allowMalformed: true);
    i += verLen;
    final count = b[i++];
    if (i + count > b.length) return null;
    final ids = b.sublist(i, i + count).toList();
    i += count;
    return (ObcAppInfo(id, version, ids), i);
  }
}
