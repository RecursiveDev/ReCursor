import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/core/network/bridge_connection_validator.dart';

void main() {
  group('BridgeConnectionValidator', () {
    test('returns valid for proper wss URL and token', () {
      final result = BridgeConnectionValidator.validate(
        url: 'wss://device.tailnet.ts.net:3000',
        token: 'valid-token-123',
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('returns invalid when URL is empty', () {
      final result = BridgeConnectionValidator.validate(
        url: '',
        token: 'token',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Bridge URL is required'));
    });

    test('returns invalid when token is empty', () {
      final result = BridgeConnectionValidator.validate(
        url: 'wss://example.com',
        token: '',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('token is required'));
    });

    test('returns invalid when URL has no scheme', () {
      final result = BridgeConnectionValidator.validate(
        url: 'device.tailnet.ts.net:3000',
        token: 'token',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('valid bridge URL'));
    });

    test('returns invalid when URL uses http', () {
      final result = BridgeConnectionValidator.validate(
        url: 'http://device.tailnet.ts.net:3000',
        token: 'token',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('wss://'));
    });

    test('returns invalid when URL uses ws (non-secure)', () {
      final result = BridgeConnectionValidator.validate(
        url: 'ws://device.tailnet.ts.net:3000',
        token: 'token',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('must use wss://'));
    });

    test('trims whitespace from URL and token before validation', () {
      final result = BridgeConnectionValidator.validate(
        url: '  wss://device.tailnet.ts.net:3000  ',
        token: '  token-with-spaces  ',
      );

      expect(result.isValid, isTrue);
    });

    test('returns valid for localhost wss with port', () {
      final result = BridgeConnectionValidator.validate(
        url: 'wss://localhost:3000',
        token: 'local-token',
      );

      expect(result.isValid, isTrue);
    });

    test('returns invalid for malformed URI', () {
      final result = BridgeConnectionValidator.validate(
        url: 'not a valid url',
        token: 'token',
      );

      expect(result.isValid, isFalse);
    });
  });

  group('BridgeConnectionException', () {
    test('stores and returns message', () {
      const exception = BridgeConnectionException('Test error message');

      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'Test error message');
    });
  });
}
