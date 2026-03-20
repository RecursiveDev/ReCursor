import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_models.freezed.dart';
part 'message_models.g.dart';

enum MessageRole { user, agent, system }

enum MessageType { text, toolCall, toolResult, system }

@freezed
class MessagePart with _$MessagePart {
  const factory MessagePart.text({
    required String content,
  }) = TextPart;

  const factory MessagePart.toolUse({
    required String tool,
    required Map<String, dynamic> params,
    String? id,
  }) = ToolUsePart;

  const factory MessagePart.toolResult({
    required String toolCallId,
    required ToolResult result,
  }) = ToolResultPart;

  const factory MessagePart.thinking({
    required String content,
  }) = ThinkingPart;

  factory MessagePart.fromJson(Map<String, dynamic> json) =>
      _$MessagePartFromJson(json);
}

@freezed
class ToolResult with _$ToolResult {
  const factory ToolResult({
    required bool success,
    required String content,
    Map<String, dynamic>? metadata,
    String? error,
    int? durationMs,
  }) = _ToolResult;

  factory ToolResult.fromJson(Map<String, dynamic> json) =>
      _$ToolResultFromJson(json);
}

enum RiskLevel { low, medium, high, critical }

enum ApprovalDecision { pending, approved, rejected, modified }

@freezed
class ToolCall with _$ToolCall {
  const factory ToolCall({
    required String id,
    required String sessionId,
    required String tool,
    required Map<String, dynamic> params,
    String? description,
    String? reasoning,
    @Default(RiskLevel.low) RiskLevel riskLevel,
    @Default(ApprovalDecision.pending) ApprovalDecision decision,
    String? modifications,
    Map<String, dynamic>? result,
    required DateTime createdAt,
    DateTime? decidedAt,
  }) = _ToolCall;

  factory ToolCall.fromJson(Map<String, dynamic> json) =>
      _$ToolCallFromJson(json);
}

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String sessionId,
    required MessageRole role,
    required String content,
    required MessageType type,
    required List<MessagePart> parts,
    Map<String, dynamic>? metadata,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(true) bool synced,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
