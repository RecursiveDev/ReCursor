import 'dart:convert';

import 'package:uuid/uuid.dart';

enum BridgeMessageType {
  // Connection
  auth,
  connectionAck,
  connectionError,
  healthCheck,
  healthStatus,
  acknowledgeWarning,
  acknowledgmentAccepted,
  heartbeatPing,
  heartbeatPong,
  // Sessions
  sessionStart,
  sessionReady,
  sessionEnd,
  // Chat
  message,
  streamStart,
  streamChunk,
  streamEnd,
  // Tools
  toolCall,
  claudeEvent,
  approvalRequired,
  approvalResponse,
  toolResult,
  // Git
  gitStatusRequest,
  gitStatusResponse,
  gitCommit,
  gitDiff,
  gitDiffResponse,
  // Files
  fileList,
  fileListResponse,
  fileRead,
  fileReadResponse,
  // Notifications
  notification,
  notificationAck,
  // Errors
  error,
}

BridgeMessageType _typeFromString(String type) {
  return switch (type) {
    'auth' => BridgeMessageType.auth,
    'connection_ack' => BridgeMessageType.connectionAck,
    'connection_error' => BridgeMessageType.connectionError,
    'health_check' => BridgeMessageType.healthCheck,
    'health_status' => BridgeMessageType.healthStatus,
    'acknowledge_warning' => BridgeMessageType.acknowledgeWarning,
    'acknowledgment_accepted' => BridgeMessageType.acknowledgmentAccepted,
    'heartbeat_ping' => BridgeMessageType.heartbeatPing,
    'heartbeat_pong' => BridgeMessageType.heartbeatPong,
    'session_start' => BridgeMessageType.sessionStart,
    'session_ready' => BridgeMessageType.sessionReady,
    'session_end' => BridgeMessageType.sessionEnd,
    'message' => BridgeMessageType.message,
    'stream_start' => BridgeMessageType.streamStart,
    'stream_chunk' => BridgeMessageType.streamChunk,
    'stream_end' => BridgeMessageType.streamEnd,
    'tool_call' => BridgeMessageType.toolCall,
    'claude_event' => BridgeMessageType.claudeEvent,
    'approval_required' => BridgeMessageType.approvalRequired,
    'approval_response' => BridgeMessageType.approvalResponse,
    'tool_result' => BridgeMessageType.toolResult,
    'git_status_request' => BridgeMessageType.gitStatusRequest,
    'git_status_response' => BridgeMessageType.gitStatusResponse,
    'git_commit' => BridgeMessageType.gitCommit,
    'git_diff' => BridgeMessageType.gitDiff,
    'git_diff_response' => BridgeMessageType.gitDiffResponse,
    'file_list' => BridgeMessageType.fileList,
    'file_list_response' => BridgeMessageType.fileListResponse,
    'file_read' => BridgeMessageType.fileRead,
    'file_read_response' => BridgeMessageType.fileReadResponse,
    'notification' => BridgeMessageType.notification,
    'notification_ack' => BridgeMessageType.notificationAck,
    'error' => BridgeMessageType.error,
    _ => BridgeMessageType.error,
  };
}

String _typeToString(BridgeMessageType type) {
  return switch (type) {
    BridgeMessageType.auth => 'auth',
    BridgeMessageType.connectionAck => 'connection_ack',
    BridgeMessageType.connectionError => 'connection_error',
    BridgeMessageType.healthCheck => 'health_check',
    BridgeMessageType.healthStatus => 'health_status',
    BridgeMessageType.acknowledgeWarning => 'acknowledge_warning',
    BridgeMessageType.acknowledgmentAccepted => 'acknowledgment_accepted',
    BridgeMessageType.heartbeatPing => 'heartbeat_ping',
    BridgeMessageType.heartbeatPong => 'heartbeat_pong',
    BridgeMessageType.sessionStart => 'session_start',
    BridgeMessageType.sessionReady => 'session_ready',
    BridgeMessageType.sessionEnd => 'session_end',
    BridgeMessageType.message => 'message',
    BridgeMessageType.streamStart => 'stream_start',
    BridgeMessageType.streamChunk => 'stream_chunk',
    BridgeMessageType.streamEnd => 'stream_end',
    BridgeMessageType.toolCall => 'tool_call',
    BridgeMessageType.claudeEvent => 'claude_event',
    BridgeMessageType.approvalRequired => 'approval_required',
    BridgeMessageType.approvalResponse => 'approval_response',
    BridgeMessageType.toolResult => 'tool_result',
    BridgeMessageType.gitStatusRequest => 'git_status_request',
    BridgeMessageType.gitStatusResponse => 'git_status_response',
    BridgeMessageType.gitCommit => 'git_commit',
    BridgeMessageType.gitDiff => 'git_diff',
    BridgeMessageType.gitDiffResponse => 'git_diff_response',
    BridgeMessageType.fileList => 'file_list',
    BridgeMessageType.fileListResponse => 'file_list_response',
    BridgeMessageType.fileRead => 'file_read',
    BridgeMessageType.fileReadResponse => 'file_read_response',
    BridgeMessageType.notification => 'notification',
    BridgeMessageType.notificationAck => 'notification_ack',
    BridgeMessageType.error => 'error',
  };
}

const _uuid = Uuid();

class BridgeMessage {
  final BridgeMessageType type;
  final String? id;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const BridgeMessage({
    required this.type,
    this.id,
    required this.timestamp,
    required this.payload,
  });

  factory BridgeMessage.auth({
    required String token,
    required String clientVersion,
    required String platform,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.auth,
      id: 'auth-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'token': token,
        'client_version': clientVersion,
        'platform': platform,
      },
    );
  }

  factory BridgeMessage.healthCheck({required String clientNonce}) {
    return BridgeMessage(
      type: BridgeMessageType.healthCheck,
      id: 'health-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'client_nonce': clientNonce,
        'client_capabilities': ['health_v1', 'acknowledgment_v1'],
      },
    );
  }

  factory BridgeMessage.acknowledgeWarning({required String warningCode}) {
    return BridgeMessage(
      type: BridgeMessageType.acknowledgeWarning,
      id: 'ack-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'warning_code': warningCode,
        'acknowledged': true,
        'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  factory BridgeMessage.heartbeatPing() {
    return BridgeMessage(
      type: BridgeMessageType.heartbeatPing,
      timestamp: DateTime.now().toUtc(),
      payload: {},
    );
  }

  factory BridgeMessage.sessionStart({
    required String agent,
    String? sessionId,
    required String workingDirectory,
    bool resume = false,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.sessionStart,
      id: 'req-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'agent': agent,
        'session_id': sessionId,
        'working_directory': workingDirectory,
        'resume': resume,
      },
    );
  }

  factory BridgeMessage.message({
    required String sessionId,
    required String content,
    String role = 'user',
  }) {
    return BridgeMessage(
      type: BridgeMessageType.message,
      id: 'msg-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'session_id': sessionId,
        'content': content,
        'role': role,
      },
    );
  }

  factory BridgeMessage.approvalResponse({
    required String sessionId,
    required String toolCallId,
    required String decision,
    Map<String, dynamic>? modifications,
    String? correlationId,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.approvalResponse,
      id: correlationId ?? 'resp-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'session_id': sessionId,
        'tool_call_id': toolCallId,
        'decision': decision,
        'modifications': modifications,
      },
    );
  }

  factory BridgeMessage.sessionEnd({
    required String sessionId,
    String reason = 'user_request',
  }) {
    return BridgeMessage(
      type: BridgeMessageType.sessionEnd,
      timestamp: DateTime.now().toUtc(),
      payload: {
        'session_id': sessionId,
        'reason': reason,
      },
    );
  }

  factory BridgeMessage.gitStatusRequest({required String sessionId}) {
    return BridgeMessage(
      type: BridgeMessageType.gitStatusRequest,
      id: 'git-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {'session_id': sessionId},
    );
  }

  factory BridgeMessage.gitCommit({
    required String sessionId,
    required String commitMessage,
    List<String>? files,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.gitCommit,
      id: 'git-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'session_id': sessionId,
        'message': commitMessage,
        'files': files,
      },
    );
  }

  factory BridgeMessage.gitDiff({
    required String sessionId,
    List<String>? files,
    bool cached = false,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.gitDiff,
      id: 'git-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'session_id': sessionId,
        'files': files,
        'cached': cached,
      },
    );
  }

  factory BridgeMessage.fileList({
    required String sessionId,
    required String path,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.fileList,
      id: 'file-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {'session_id': sessionId, 'path': path},
    );
  }

  factory BridgeMessage.fileRead({
    required String sessionId,
    required String path,
    int offset = 0,
    int? limit,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.fileRead,
      id: 'file-${_uuid.v4()}',
      timestamp: DateTime.now().toUtc(),
      payload: {
        'session_id': sessionId,
        'path': path,
        'offset': offset,
        if (limit != null) 'limit': limit,
      },
    );
  }

  factory BridgeMessage.notificationAck({
    required List<String> notificationIds,
  }) {
    return BridgeMessage(
      type: BridgeMessageType.notificationAck,
      timestamp: DateTime.now().toUtc(),
      payload: {'notification_ids': notificationIds},
    );
  }

  factory BridgeMessage.fromJson(Map<String, dynamic> json) {
    return BridgeMessage(
      type: _typeFromString(json['type'] as String),
      id: json['id'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now().toUtc(),
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': _typeToString(type),
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() => 'BridgeMessage(type: $type, id: $id)';
}
