// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AgentConfigImpl _$$AgentConfigImplFromJson(Map<String, dynamic> json) =>
    _$AgentConfigImpl(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      type: $enumDecode(_$AgentTypeEnumMap, json['type']),
      bridgeUrl: json['bridgeUrl'] as String,
      authToken: json['authToken'] as String,
      workingDirectory: json['workingDirectory'] as String?,
      status:
          $enumDecodeNullable(_$AgentConnectionStatusEnumMap, json['status']) ??
              AgentConnectionStatus.disconnected,
      lastConnectedAt: json['lastConnectedAt'] == null
          ? null
          : DateTime.parse(json['lastConnectedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AgentConfigImplToJson(_$AgentConfigImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'type': _$AgentTypeEnumMap[instance.type]!,
      'bridgeUrl': instance.bridgeUrl,
      'authToken': instance.authToken,
      'workingDirectory': instance.workingDirectory,
      'status': _$AgentConnectionStatusEnumMap[instance.status]!,
      'lastConnectedAt': instance.lastConnectedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$AgentTypeEnumMap = {
  AgentType.claudeCode: 'claudeCode',
  AgentType.openCode: 'openCode',
  AgentType.aider: 'aider',
  AgentType.goose: 'goose',
  AgentType.custom: 'custom',
};

const _$AgentConnectionStatusEnumMap = {
  AgentConnectionStatus.connected: 'connected',
  AgentConnectionStatus.disconnected: 'disconnected',
  AgentConnectionStatus.inactive: 'inactive',
};
