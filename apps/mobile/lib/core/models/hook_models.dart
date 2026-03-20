import 'package:freezed_annotation/freezed_annotation.dart';

part 'hook_models.freezed.dart';
part 'hook_models.g.dart';

enum HookEventType {
  sessionStart,
  sessionEnd,
  preToolUse,
  postToolUse,
  userPromptSubmit,
  stop,
  subagentStop,
  preCompact,
  notification,
}

@freezed
class HookEvent with _$HookEvent {
  const factory HookEvent({
    required String eventType,
    required String sessionId,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) = _HookEvent;

  factory HookEvent.fromJson(Map<String, dynamic> json) =>
      _$HookEventFromJson(json);
}
