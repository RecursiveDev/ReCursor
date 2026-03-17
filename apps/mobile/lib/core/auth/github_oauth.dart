import 'dart:convert';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// IMPORTANT: OAuth exchange requires the client secret, which must NEVER be
// embedded in the mobile app binary. A proper production implementation routes
// the code→token exchange through a server-side endpoint that holds the secret.
// This class documents the flow; the `handleCallback` method is a placeholder
// that highlights this constraint.
// ---------------------------------------------------------------------------

// Replace with your actual GitHub OAuth App credentials.
// The client secret MUST be stored server-side only.
const String _kGitHubClientId = 'YOUR_GITHUB_CLIENT_ID';
const String _kRedirectUri = 'recursor://auth/callback';

/// Handles GitHub OAuth login and Personal Access Token (PAT) validation.
class GitHubOAuth {
  const GitHubOAuth();

  /// Returns the GitHub Authorization URL to open in a WebView.
  ///
  /// After the user authorizes, GitHub redirects to [_kRedirectUri] with a
  /// `?code=` parameter. Pass that code to [handleCallback].
  String startOAuthFlow() {
    final params = Uri(queryParameters: {
      'client_id': _kGitHubClientId,
      'redirect_uri': _kRedirectUri,
      'scope': 'read:user repo',
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    }).query;

    return 'https://github.com/login/oauth/authorize?$params';
  }

  /// Exchange the OAuth [code] for an access token.
  ///
  /// NOTE: This call requires the client secret. In production, proxy the
  /// exchange through a first-party backend endpoint (e.g. POST /auth/github).
  /// The implementation below is intentionally left as a commented-out stub.
  Future<String> handleCallback(String code) async {
    // TODO(server-side): Route this through a backend endpoint that holds the
    // client secret. Direct exchange from the mobile client is insecure.
    //
    // Example server-side call:
    //   POST https://your-backend.example.com/auth/github/callback
    //   Body: { "code": code }
    //   Response: { "access_token": "gho_xxx" }
    throw UnimplementedError(
      'OAuth code exchange must be performed server-side to protect the '
      'client secret. Implement a backend endpoint that exchanges the code '
      'and returns the access token to the mobile client.',
    );
  }

  /// Validate a GitHub Personal Access Token against the GitHub API.
  ///
  /// Returns `true` if the token is valid (i.e. the `/user` endpoint responds
  /// with HTTP 200).
  Future<bool> validatePAT(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch the authenticated user's profile using a validated token.
  /// Returns a map with `login` and `avatar_url` fields.
  Future<Map<String, String>> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return {
      'login': body['login'] as String? ?? '',
      'avatar_url': body['avatar_url'] as String? ?? '',
    };
  }
}
