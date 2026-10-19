import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/game_action.dart';
import '../../diagnostics/app_log.dart';
import '../game_output.dart';
import 'mdns_advertiser.dart';
import 'obc_codec.dart';

/// OpenBikeControl "network device": a TCP server announced over mDNS that
/// MyWhoosh connects to.
class ObcOutput implements GameOutput {
  ObcOutput({
    required this._advertiser,
    required this._log,
    this._port = defaultPort,
    InternetAddress? bindAddress,
    String? instanceName,
    this._statusEvery = const Duration(seconds: 30),
  })  : _bindAddress = bindAddress ?? InternetAddress.anyIPv4,
        instanceName = instanceName ?? 'ShiftPad-${Platform.localHostname}';

  final MdnsAdvertiser _advertiser;
  final AppLog _log;
  /// Fixed so the app finds ShiftPad on the same port after a restart.
  /// 0 picks any free port.
  static const defaultPort = 47331;

  final int _port;
  final InternetAddress _bindAddress;
  final Duration _statusEvery;
  final String instanceName;

  final _available = ValueNotifier(false);
  final _appName = ValueNotifier<String?>(null);
  ServerSocket? _server;
  Socket? _client;
  Timer? _status;

  @override
  ValueListenable<bool> get available => _available;

  /// App id sent by the connected app (e.g. "mywhoosh"), if any.
  ValueListenable<String?> get connectedAppName => _appName;

  /// Port the server listens on, once started.
  int? get port => _server?.port;

  /// Buttons the connected app said it handles; empty means all.
  List<int> _appButtons = const [];

  @override
  bool supports(GameAction action) {
    final id = obcButtonId(action);
    return id != null && (_appButtons.isEmpty || _appButtons.contains(id));
  }

  @override
  Future<void> start() async {
    if (_server != null) return;
    ServerSocket server;
    try {
      server = await ServerSocket.bind(_bindAddress, _port);
    } on SocketException catch (e) {
      if (_port == 0) rethrow;
      _log.info('obc', 'port $_port busy ($e), using any free port');
      server = await ServerSocket.bind(_bindAddress, 0);
    }
    _server = server;
    server.listen(_onClient);
    _log.info('obc', 'listening on port ${server.port}');
    try {
      await _advertiser.register(
        instanceName: instanceName,
        serviceType: kObcServiceType,
        port: server.port,
        txt: {
          'version': '1',
          'id': instanceName.toLowerCase(),
          'name': 'ShiftPad',
          'service-uuids': kObcBleServiceUuid,
          'manufacturer': 'ShiftPad',
          'model': 'ShiftPad for Windows',
        },
      );
    } catch (e) {
      _log.info('obc', 'mDNS announce failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    _status?.cancel();
    _status = null;
    _client?.destroy();
    _client = null;
    _available.value = false;
    _appName.value = null;
    await _server?.close();
    _server = null;
    try {
      await _advertiser.unregister();
    } catch (e) {
      _log.info('obc', 'mDNS unregister failed: $e');
    }
  }

  void _onClient(Socket socket) {
    final previous = _client;
    if (previous != null) {
      _log.info('obc', 'new app connection replaces the previous one');
      previous.destroy();
    }
    _client = socket;
    socket.setOption(SocketOption.tcpNoDelay, true);
    final from = '${socket.remoteAddress.address}:${socket.remotePort}';
    _log.info('obc', 'app connected from $from');
    _appName.value = null;
    _appButtons = const [];
    _available.value = true;

    final reader = ObcAppMessageReader();
    socket.listen(
      (data) {
        for (final info in reader.add(data)) {
          _log.info('obc', 'app info: ${info.appId} ${info.appVersion} '
              'buttons ${info.buttonIds.map((b) => '0x${b.toRadixString(16)}').join(',')}');
          if (identical(_client, socket)) {
            _appButtons = info.buttonIds;
            _appName.value = info.appId;
          }
        }
      },
      onDone: () => _onClientGone(socket, 'closed'),
      onError: (Object e) => _onClientGone(socket, 'error $e'),
      cancelOnError: true,
    );

    _write(socket, encodeObcStatus());
    _status?.cancel();
    _status = Timer.periodic(_statusEvery, (_) {
      final c = _client;
      if (c != null) _write(c, encodeObcStatus());
    });
  }

  void _onClientGone(Socket socket, String why) {
    if (!identical(_client, socket)) return;
    _log.info('obc', 'app disconnected ($why)');
    _client = null;
    _status?.cancel();
    _status = null;
    _available.value = false;
    _appName.value = null;
    _appButtons = const [];
    socket.destroy();
  }

  void _write(Socket socket, List<int> bytes) {
    try {
      socket.add(bytes);
    } catch (e) {
      _onClientGone(socket, 'write failed: $e');
    }
  }

  @override
  Future<void> send(GameAction action, {required bool pressed}) async {
    final id = obcButtonId(action);
    final client = _client;
    if (id == null || client == null) return;
    _write(client, encodeObcButton(id, pressed));
  }
}
