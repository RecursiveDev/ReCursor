import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/bridge_connection_validator.dart';
import 'package:recursor_mobile/core/network/connection_state.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/storage/preferences.dart';
import 'package:recursor_mobile/core/storage/secure_token_storage.dart';
import 'package:recursor_mobile/features/startup/domain/bridge_startup_controller.dart';

void main() {
  group('BridgeStartupController', () {
    test('returns bridge setup when no saved pairing exists', () async {
      final controller = BridgeStartupController(
        preferences: FakeAppPreferences(),
        tokenStorage: FakeSecureTokenStorage(),
        webSocketService: FakeStartupWebSocketService(),
      );

      final result = await controller.restore();

      expect(result.destination, AppStartupDestination.bridgeSetup);
      expect(result.message, isNull);
    });

    test('returns bridge setup with validation error when URL is invalid',
        () async {
      final controller = BridgeStartupController(
        preferences: FakeAppPreferences(bridgeUrl: 'http://invalid.com'),
        tokenStorage: FakeSecureTokenStorage(token: 'token-123'),
        webSocketService: FakeStartupWebSocketService(),
      );

      final result = await controller.restore();

      expect(result.destination, AppStartupDestination.bridgeSetup);
      expect(result.message, contains('Invalid saved bridge configuration'));
    });

    test('returns bridge setup with validation error when URL is not wss',
        () async {
      final controller = BridgeStartupController(
        preferences: FakeAppPreferences(bridgeUrl: 'ws://device.ts.net:3000'),
        tokenStorage: FakeSecureTokenStorage(token: 'token-123'),
        webSocketService: FakeStartupWebSocketService(),
      );

      final result = await controller.restore();

      expect(result.destination, AppStartupDestination.bridgeSetup);
      expect(result.message, contains('must use wss://'));
    });

    test('restores the saved bridge pairing and opens health verification',
        () async {
      final service = FakeStartupWebSocketService();
      final controller = BridgeStartupController(
        preferences: FakeAppPreferences(
          bridgeUrl: 'wss://device.tailnet.ts.net:3000',
        ),
        tokenStorage: FakeSecureTokenStorage(token: 'bridge-token-123'),
        webSocketService: service,
      );

      final result = await controller.restore();

      expect(result.destination, AppStartupDestination.healthVerification);
      expect(service.lastUrl, 'wss://device.tailnet.ts.net:3000');
      expect(service.lastToken, 'bridge-token-123');
      expect(service.currentStatus, ConnectionStatus.connected);
    });

    test('falls back to bridge setup when reconnecting fails', () async {
      final controller = BridgeStartupController(
        preferences: FakeAppPreferences(
          bridgeUrl: 'wss://device.tailnet.ts.net:3000',
        ),
        tokenStorage: FakeSecureTokenStorage(token: 'bridge-token-123'),
        webSocketService: FakeStartupWebSocketService(
          error: const BridgeConnectionException('Invalid token'),
        ),
      );

      final result = await controller.restore();

      expect(result.destination, AppStartupDestination.bridgeSetup);
      expect(result.message, contains('Unable to reconnect'));
      expect(result.message, contains('Invalid token'));
    });
  });
}

class FakeAppPreferences extends AppPreferences {
  FakeAppPreferences({this.bridgeUrl});

  String? bridgeUrl;

  @override
  String? getBridgeUrl() {
    return bridgeUrl;
  }

  @override
  Future<void> setBridgeUrl(String? url) async {
    bridgeUrl = url;
  }
}

class FakeSecureTokenStorage extends SecureTokenStorage {
  FakeSecureTokenStorage({this.token}) : super(const FlutterSecureStorage());

  String? token;

  @override
  Future<String?> getToken(String key) async {
    return token;
  }

  @override
  Future<void> saveToken(String key, String value) async {
    token = value;
  }
}

class FakeStartupWebSocketService extends WebSocketService {
  FakeStartupWebSocketService({this.error});

  final Object? error;
  String? lastUrl;
  String? lastToken;
  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;

  @override
  ConnectionStatus get currentStatus => _currentStatus;

  @override
  Future<void> connect({required String url, required String token}) async {
    lastUrl = url;
    lastToken = token;
    if (error != null) {
      throw error!;
    }
    _currentStatus = ConnectionStatus.connected;
  }
}
