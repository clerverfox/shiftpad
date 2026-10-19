/// Announces a DNS-SD service on the local network.
abstract class MdnsAdvertiser {
  /// Registers `<instanceName>.<serviceType>.local` on [port].
  Future<void> register({
    required String instanceName,
    required String serviceType,
    required int port,
    required Map<String, String> txt,
  });

  Future<void> unregister();
}

/// For platforms without an advertiser yet.
class NoopMdnsAdvertiser implements MdnsAdvertiser {
  const NoopMdnsAdvertiser();

  @override
  Future<void> register({
    required String instanceName,
    required String serviceType,
    required int port,
    required Map<String, String> txt,
  }) async {}

  @override
  Future<void> unregister() async {}
}
