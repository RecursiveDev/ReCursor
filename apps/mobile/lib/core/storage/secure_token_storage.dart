import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String kBridgeToken = 'bridge_token';

/// Secure key-value storage for bridge pairing tokens.
///
/// Backed by [FlutterSecureStorage] (Keychain on iOS, Keystore on Android).
class SecureTokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getToken(String key) async {
    return _storage.read(key: key);
  }

  Future<void> deleteToken(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
