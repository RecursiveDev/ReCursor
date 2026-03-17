import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_repository.dart';
import 'auth_state.dart';
import 'github_oauth.dart';
import 'token_storage.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final _secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final _tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.read(_secureStorageProvider));
});

final _gitHubOAuthProvider = Provider<GitHubOAuth>((ref) {
  return const GitHubOAuth();
});

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    tokenStorage: ref.read(_tokenStorageProvider),
    gitHubOAuth: ref.read(_gitHubOAuthProvider),
  );
});

// ---------------------------------------------------------------------------
// AuthStateNotifier
// ---------------------------------------------------------------------------

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final authenticated = await _repository.isAuthenticated();
      if (authenticated) {
        final token = await _repository.getStoredToken();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          accessToken: token,
          tokenType: 'pat',
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithOAuth(String code) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.signInWithOAuth(code);
      final token = await _repository.getStoredToken();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: token,
        tokenType: 'oauth',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithPAT(String token) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final profile = await _repository.signInWithPAT(token);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        accessToken: token,
        username: profile['login'],
        avatarUrl: profile['avatar_url'],
        tokenType: 'pat',
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ---------------------------------------------------------------------------
// AuthState provider
// ---------------------------------------------------------------------------

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(authRepositoryProvider));
});
