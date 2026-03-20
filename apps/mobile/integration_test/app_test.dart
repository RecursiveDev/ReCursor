import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recursor_mobile/app.dart';
import 'package:recursor_mobile/core/network/websocket_service.dart';
import 'package:recursor_mobile/core/providers/theme_provider.dart';
import 'package:recursor_mobile/core/providers/token_storage_provider.dart';
import 'package:recursor_mobile/core/storage/preferences.dart';
import 'package:recursor_mobile/core/storage/secure_token_storage.dart';
import 'package:recursor_mobile/features/startup/domain/bridge_startup_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch routes to bridge setup without any login workflow', (
    tester,
  ) async {
    final preferences = FakeAppPreferences();
    final tokenStorage = FakeSecureTokenStorage();
    final startupController = FakeBridgeStartupController(
      const AppStartupResult.bridgeSetup(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(preferences),
          tokenStorageProvider.overrideWithValue(tokenStorage),
          bridgeStartupControllerProvider.overrideWithValue(startupController),
        ],
        child: const ReCursorApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bridgeSetupScreen')), findsOneWidget);
    expect(find.text('Bridge Setup'), findsOneWidget);
    expect(find.textContaining('Sign in'), findsNothing);
    expect(find.textContaining('GitHub'), findsNothing);
  });
}

class FakeBridgeStartupController extends BridgeStartupController {
  FakeBridgeStartupController(this.result)
      : super(
          preferences: FakeAppPreferences(),
          tokenStorage: FakeSecureTokenStorage(),
          webSocketService: _NoopWebSocketService(),
        );

  final AppStartupResult result;

  @override
  Future<AppStartupResult> restore() async {
    return result;
  }
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
}

class _NoopWebSocketService extends WebSocketService {}
