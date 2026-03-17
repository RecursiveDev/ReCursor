import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_models.freezed.dart';
part 'agent_models.g.dart';

enum AgentType { claudeCode, openCode, aider, goose, custom }

enum AgentConnectionStatus { connected, disconnected, inactive }

@freezed
class AgentConfig with _$AgentConfig {
  const factory AgentConfig({
    required String id,
    required String displayName,
    required AgentType type,
    required String bridgeUrl,
    required String authToken,
    String? workingDirectory,
    @Default(AgentConnectionStatus.disconnected) AgentConnectionStatus status,
    DateTime? lastConnectedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AgentConfig;

  factory AgentConfig.fromJson(Map<String, dynamic> json) =>
      _$AgentConfigFromJson(json);
}
