import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_models.freezed.dart';
part 'session_models.g.dart';

enum SessionStatus { active, paused, closed }

enum SessionEventType {
  userMessage,
  agentMessage,
  toolUse,
  toolResult,
  sessionStart,
  sessionEnd,
  hookEvent,
}

@freezed
class ChatSession with _$ChatSession {
  const factory ChatSession({
    required String id,
    required String agentType,
    String? agentId,
    @Default('') String title,
    required String workingDirectory,
    String? branch,
    @Default(SessionStatus.active) SessionStatus status,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
    @Default(true) bool synced,
  }) = _ChatSession;

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
}

@freezed
class SessionEvent with _$SessionEvent {
  const factory SessionEvent({
    required String id,
    required String sessionId,
    required SessionEventType eventType,
    required String title,
    String? description,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) = _SessionEvent;

  factory SessionEvent.fromJson(Map<String, dynamic> json) =>
      _$SessionEventFromJson(json);
}
