// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TextPartImpl _$$TextPartImplFromJson(Map<String, dynamic> json) =>
    _$TextPartImpl(
      content: json['content'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TextPartImplToJson(_$TextPartImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'runtimeType': instance.$type,
    };

_$ToolUsePartImpl _$$ToolUsePartImplFromJson(Map<String, dynamic> json) =>
    _$ToolUsePartImpl(
      tool: json['tool'] as String,
      params: json['params'] as Map<String, dynamic>,
      id: json['id'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ToolUsePartImplToJson(_$ToolUsePartImpl instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'params': instance.params,
      'id': instance.id,
      'runtimeType': instance.$type,
    };

_$ToolResultPartImpl _$$ToolResultPartImplFromJson(Map<String, dynamic> json) =>
    _$ToolResultPartImpl(
      toolCallId: json['toolCallId'] as String,
      result: ToolResult.fromJson(json['result'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ToolResultPartImplToJson(
        _$ToolResultPartImpl instance) =>
    <String, dynamic>{
      'toolCallId': instance.toolCallId,
      'result': instance.result,
      'runtimeType': instance.$type,
    };

_$ThinkingPartImpl _$$ThinkingPartImplFromJson(Map<String, dynamic> json) =>
    _$ThinkingPartImpl(
      content: json['content'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ThinkingPartImplToJson(_$ThinkingPartImpl instance) =>
    <String, dynamic>{
      'content': instance.content,
      'runtimeType': instance.$type,
    };

_$ToolResultImpl _$$ToolResultImplFromJson(Map<String, dynamic> json) =>
    _$ToolResultImpl(
      success: json['success'] as bool,
      content: json['content'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ToolResultImplToJson(_$ToolResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'content': instance.content,
      'metadata': instance.metadata,
      'error': instance.error,
      'durationMs': instance.durationMs,
    };

_$ToolCallImpl _$$ToolCallImplFromJson(Map<String, dynamic> json) =>
    _$ToolCallImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      tool: json['tool'] as String,
      params: json['params'] as Map<String, dynamic>,
      description: json['description'] as String?,
      reasoning: json['reasoning'] as String?,
      riskLevel: $enumDecodeNullable(_$RiskLevelEnumMap, json['riskLevel']) ??
          RiskLevel.low,
      decision:
          $enumDecodeNullable(_$ApprovalDecisionEnumMap, json['decision']) ??
              ApprovalDecision.pending,
      modifications: json['modifications'] as String?,
      result: json['result'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
    );

Map<String, dynamic> _$$ToolCallImplToJson(_$ToolCallImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'tool': instance.tool,
      'params': instance.params,
      'description': instance.description,
      'reasoning': instance.reasoning,
      'riskLevel': _$RiskLevelEnumMap[instance.riskLevel]!,
      'decision': _$ApprovalDecisionEnumMap[instance.decision]!,
      'modifications': instance.modifications,
      'result': instance.result,
      'createdAt': instance.createdAt.toIso8601String(),
      'decidedAt': instance.decidedAt?.toIso8601String(),
    };

const _$RiskLevelEnumMap = {
  RiskLevel.low: 'low',
  RiskLevel.medium: 'medium',
  RiskLevel.high: 'high',
  RiskLevel.critical: 'critical',
};

const _$ApprovalDecisionEnumMap = {
  ApprovalDecision.pending: 'pending',
  ApprovalDecision.approved: 'approved',
  ApprovalDecision.rejected: 'rejected',
  ApprovalDecision.modified: 'modified',
};

_$MessageImpl _$$MessageImplFromJson(Map<String, dynamic> json) =>
    _$MessageImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: $enumDecode(_$MessageRoleEnumMap, json['role']),
      content: json['content'] as String,
      type: $enumDecode(_$MessageTypeEnumMap, json['type']),
      parts: (json['parts'] as List<dynamic>)
          .map((e) => MessagePart.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      synced: json['synced'] as bool? ?? true,
    );

Map<String, dynamic> _$$MessageImplToJson(_$MessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'parts': instance.parts,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'synced': instance.synced,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.agent: 'agent',
  MessageRole.system: 'system',
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.toolCall: 'toolCall',
  MessageType.toolResult: 'toolResult',
  MessageType.system: 'system',
};
