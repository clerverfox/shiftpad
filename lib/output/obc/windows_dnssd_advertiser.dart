import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'mdns_advertiser.dart';

/// mDNS registration through the DNS-SD API built into Windows 10+
/// (`DnsServiceRegister` in dnsapi.dll), so Bonjour is not needed.
class WindowsDnsSdAdvertiser implements MdnsAdvertiser {
  WindowsDnsSdAdvertiser({this._onInfo});

  final void Function(String message)? _onInfo;

  Arena? _arena;
  Pointer<DNS_SERVICE_REGISTER_REQUEST>? _request;
  NativeCallable<PDNS_SERVICE_REGISTER_COMPLETE>? _callback;
  Completer<int>? _pending;

  @override
  Future<void> register({
    required String instanceName,
    required String serviceType,
    required int port,
    required Map<String, String> txt,
  }) async {
    await unregister();
    final arena = _arena = Arena();
    final host = '${Platform.localHostname}.local';

    final instance = arena<DNS_SERVICE_INSTANCE>();
    instance.ref
      ..pszInstanceName =
          PWSTR('$instanceName.$serviceType.local'.toNativeUtf16(allocator: arena))
      ..pszHostName = PWSTR(host.toNativeUtf16(allocator: arena))
      ..wPort = port
      ..dwPropertyCount = txt.length
      ..keys = arena<Pointer<Utf16>>(txt.length)
      ..values = arena<Pointer<Utf16>>(txt.length);
    var i = 0;
    for (final MapEntry(:key, :value) in txt.entries) {
      instance.ref.keys[i] = key.toNativeUtf16(allocator: arena);
      instance.ref.values[i] = value.toNativeUtf16(allocator: arena);
      i++;
    }

    _callback = NativeCallable<PDNS_SERVICE_REGISTER_COMPLETE>.listener(
      (int status, Pointer _, Pointer<DNS_SERVICE_INSTANCE> _) {
        _pending?.complete(status);
        _pending = null;
      },
    );
    final request = _request = arena<DNS_SERVICE_REGISTER_REQUEST>();
    request.ref
      ..Version = DNS_QUERY_REQUEST_VERSION1
      ..InterfaceIndex = 0
      ..pServiceInstance = instance
      ..pRegisterCompletionCallback = _callback!.nativeFunction
      ..pQueryContext = nullptr
      ..unicastEnabled = false;

    final done = (_pending = Completer<int>()).future;
    final result = DnsServiceRegister(request, null).value;
    if (result != DNS_REQUEST_PENDING) {
      _pending = null;
      _release();
      throw OSError('DnsServiceRegister returned $result', result);
    }
    final status = await done.timeout(const Duration(seconds: 10),
        onTimeout: () => -1);
    _onInfo?.call('mDNS register "$instanceName" port $port: status $status');
    if (status != 0) {
      throw OSError('mDNS registration failed ($status)', status);
    }
  }

  @override
  Future<void> unregister() async {
    final request = _request;
    if (request == null) return;
    final done = (_pending = Completer<int>()).future;
    final result = DnsServiceDeRegister(request, null).value;
    if (result == DNS_REQUEST_PENDING) {
      await done.timeout(const Duration(seconds: 5), onTimeout: () => -1);
    }
    _pending = null;
    _onInfo?.call('mDNS unregister: $result');
    _release();
  }

  void _release() {
    _callback?.close();
    _callback = null;
    _request = null;
    _arena?.releaseAll();
    _arena = null;
  }
}
