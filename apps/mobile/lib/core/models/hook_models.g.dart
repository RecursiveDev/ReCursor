// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hook_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HookEventImpl _$$HookEventImplFromJson(Map<String, dynamic> json) =>
    _$HookEventImpl(
      eventType: json['eventType'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: json['payload'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$HookEventImplToJson(_$HookEventImpl instance) =>
    <String, dynamic>{
      'eventType': instance.eventType,
      'sessionId': instance.sessionId,
      'timestamp': instance.timestamp.toIso8601String(),
      'payload': instance.payload,
    };
