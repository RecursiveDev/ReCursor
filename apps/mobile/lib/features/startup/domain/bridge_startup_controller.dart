import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/bridge_connection_validator.dart';
import '../../../../core/network/connection_state.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/token_storage_provider.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../../core/storage/preferences.dart';
import '../../../../core/storage/secure_token_storage.dart';

final bridgeStartupControllerProvider =
    Provider<BridgeStartupController>((ref) {
  return BridgeStartupController(
    preferences: ref.read(appPreferencesProvider),
    tokenStorage: ref.read(tokenStorageProvider),
    webSocketService: ref.read(webSocketServiceProvider),
  );
});

final bridgeStartupErrorProvider = StateProvider<String?>((ref) => null);

enum AppStartupDestination { bridgeSetup, healthVerification, home }

class AppStartupResult {
  const AppStartupResult._({required this.destination, this.message});

  const AppStartupResult.bridgeSetup({String? message})
      : this._(
          destination: AppStartupDestination.bridgeSetup,
          message: message,
        );

  const AppStartupResult.healthVerification()
      : this._(destination: AppStartupDestination.healthVerification);

  const AppStartupResult.home()
      : this._(destination: AppStartupDestination.home);

  final AppStartupDestination destination;
  final String? message;
}

class BridgeStartupController {
  BridgeStartupController({
    required AppPreferences preferences,
    required SecureTokenStorage tokenStorage,
    required WebSocketService webSocketService,
  })  : _preferences = preferences,
        _tokenStorage = tokenStorage,
        _webSocketService = webSocketService;

  final AppPreferences _preferences;
  final SecureTokenStorage _tokenStorage;
  final WebSocketService _webSocketService;

  Future<AppStartupResult> restore() async {
    final savedUrl = _preferences.getBridgeUrl()?.trim();
    final savedToken = await _tokenStorage.getToken(kBridgeToken);
    final normalizedToken = savedToken?.trim();

    if (savedUrl == null ||
        savedUrl.isEmpty ||
        normalizedToken == null ||
        normalizedToken.isEmpty) {
      return const AppStartupResult.bridgeSetup();
    }

    // Validate saved credentials before attempting connection
    final validation = BridgeConnectionValidator.validate(
      url: savedUrl,
      token: normalizedToken,
    );
    if (!validation.isValid) {
      return AppStartupResult.bridgeSetup(
        message:
            'Invalid saved bridge configuration: ${validation.errorMessage}',
      );
    }

    if (_webSocketService.currentStatus == ConnectionStatus.connected) {
      return const AppStartupResult.healthVerification();
    }

    try {
      await _webSocketService.connect(url: savedUrl, token: normalizedToken);
      return const AppStartupResult.healthVerification();
    } catch (error) {
      return AppStartupResult.bridgeSetup(
        message: 'Unable to reconnect to the saved bridge. $error',
      );
    }
  }
}
