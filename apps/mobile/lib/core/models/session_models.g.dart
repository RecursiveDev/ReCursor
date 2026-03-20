// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatSessionImpl _$$ChatSessionImplFromJson(Map<String, dynamic> json) =>
    _$ChatSessionImpl(
      id: json['id'] as String,
      agentType: json['agentType'] as String,
      agentId: json['agentId'] as String?,
      title: json['title'] as String? ?? '',
      workingDirectory: json['workingDirectory'] as String,
      branch: json['branch'] as String?,
      status: $enumDecodeNullable(_$SessionStatusEnumMap, json['status']) ??
          SessionStatus.active,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      synced: json['synced'] as bool? ?? true,
    );

Map<String, dynamic> _$$ChatSessionImplToJson(_$ChatSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'agentType': instance.agentType,
      'agentId': instance.agentId,
      'title': instance.title,
      'workingDirectory': instance.workingDirectory,
      'branch': instance.branch,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastMessageAt': instance.lastMessageAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'synced': instance.synced,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.paused: 'paused',
  SessionStatus.closed: 'closed',
};

_$SessionEventImpl _$$SessionEventImplFromJson(Map<String, dynamic> json) =>
    _$SessionEventImpl(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      eventType: $enumDecode(_$SessionEventTypeEnumMap, json['eventType']),
      title: json['title'] as String,
      description: json['description'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$SessionEventImplToJson(_$SessionEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'eventType': _$SessionEventTypeEnumMap[instance.eventType]!,
      'title': instance.title,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$SessionEventTypeEnumMap = {
  SessionEventType.userMessage: 'userMessage',
  SessionEventType.agentMessage: 'agentMessage',
  SessionEventType.toolUse: 'toolUse',
  SessionEventType.toolResult: 'toolResult',
  SessionEventType.sessionStart: 'sessionStart',
  SessionEventType.sessionEnd: 'sessionEnd',
  SessionEventType.hookEvent: 'hookEvent',
};
