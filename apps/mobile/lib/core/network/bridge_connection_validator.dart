class BridgeConnectionValidationResult {
  const BridgeConnectionValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  const BridgeConnectionValidationResult.valid() : this._(isValid: true);

  const BridgeConnectionValidationResult.invalid(String message)
      : this._(isValid: false, errorMessage: message);

  final bool isValid;
  final String? errorMessage;
}

class BridgeConnectionValidator {
  const BridgeConnectionValidator._();

  static BridgeConnectionValidationResult validate({
    required String url,
    required String token,
  }) {
    final normalizedUrl = url.trim();
    final normalizedToken = token.trim();

    if (normalizedUrl.isEmpty) {
      return const BridgeConnectionValidationResult.invalid(
        'Bridge URL is required.',
      );
    }

    if (normalizedToken.isEmpty) {
      return const BridgeConnectionValidationResult.invalid(
        'Bridge auth token is required.',
      );
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return const BridgeConnectionValidationResult.invalid(
        'Enter a valid bridge URL.',
      );
    }

    if (uri.scheme != 'wss') {
      return const BridgeConnectionValidationResult.invalid(
        'Bridge URL must use wss:// to match the security contract.',
      );
    }

    return const BridgeConnectionValidationResult.valid();
  }
}

class BridgeConnectionException implements Exception {
  const BridgeConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
