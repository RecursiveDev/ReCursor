import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStatus { unauthenticated, authenticated, loading, error }

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unauthenticated) AuthStatus status,
    String? accessToken,
    String? username,
    String? avatarUrl,
    String? tokenType, // "oauth" | "pat"
    String? errorMessage,
  }) = _AuthState;
}
