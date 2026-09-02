import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal secret store boundary exposed to plugins by the host.
abstract interface class SecretStore {
  Future<String?> read(String reference);
  Future<void> write(String reference, String value);
  Future<void> delete(String reference);
}

/// Desktop-backed secret store using Windows Credential Manager, macOS
/// Keychain, or the Linux secret service through flutter_secure_storage.
class PlatformSecretStore implements SecretStore {
  PlatformSecretStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String reference) => _storage.read(key: reference);

  @override
  Future<void> write(String reference, String value) =>
      _storage.write(key: reference, value: value);

  @override
  Future<void> delete(String reference) => _storage.delete(key: reference);
}

/// Host-side bridge that keeps plugin code from accessing unrelated secrets.
class PluginSecretBridge {
  const PluginSecretBridge(this._store);

  final SecretStore _store;

  Future<String?> resolve(String reference) {
    if (reference.trim().isEmpty) return Future<String?>.value();
    return _store.read(reference.trim());
  }
}

/// In-memory adapter used by tests and by plugin development tooling.
class MemorySecretStore implements SecretStore {
  MemorySecretStore([Map<String, String>? initial])
      : _values = {...?initial};

  final Map<String, String> _values;

  @override
  Future<String?> read(String reference) async => _values[reference];

  @override
  Future<void> write(String reference, String value) async {
    _values[reference] = value;
  }

  @override
  Future<void> delete(String reference) async {
    _values.remove(reference);
  }
}
