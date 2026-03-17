import 'token_storage.dart';
import 'github_oauth.dart';

/// Repository layer for authentication operations.
/// Coordinates between [TokenStorage] and [GitHubOAuth].
class AuthRepository {
  const AuthRepository({
    required TokenStorage tokenStorage,
    required GitHubOAuth gitHubOAuth,
  })  : _storage = tokenStorage,
        _oauth = gitHubOAuth;

  final TokenStorage _storage;
  final GitHubOAuth _oauth;

  /// Exchange an OAuth code for a token and persist it.
  Future<void> signInWithOAuth(String code) async {
    final token = await _oauth.handleCallback(code);
    await _storage.saveToken(kAuthToken, token);
    await _storage.saveToken(kRefreshToken, ''); // refresh not used for PAT
  }

  /// Validate and persist a GitHub Personal Access Token.
  Future<Map<String, String>> signInWithPAT(String token) async {
    final valid = await _oauth.validatePAT(token);
    if (!valid) {
      throw Exception('Invalid Personal Access Token');
    }
    await _storage.saveToken(kAuthToken, token);
    final profile = await _oauth.fetchUserProfile(token);
    return profile;
  }

  /// Remove all stored tokens.
  Future<void> signOut() async {
    await _storage.clearAll();
  }

  /// Return the stored auth token (or null if not signed in).
  Future<String?> getStoredToken() async {
    return _storage.getToken(kAuthToken);
  }

  /// Returns true if a non-empty auth token is present in storage.
  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }
}
