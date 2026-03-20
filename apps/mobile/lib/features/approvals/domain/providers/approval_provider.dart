import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/message_models.dart';
import '../../../../core/network/websocket_messages.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../../core/storage/database.dart';
import '../approval_source.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Pending approvals (in-memory list)
// ---------------------------------------------------------------------------

class PendingApprovalsNotifier extends StateNotifier<List<ToolCall>> {
  PendingApprovalsNotifier(this._ref) : super([]) {
    _listen();
  }

  final Ref _ref;
  StreamSubscription<BridgeMessage>? _sub;

  void _listen() {
    final service = _ref.read(webSocketServiceProvider);
    _sub = service.messages.listen((msg) {
      if (msg.type == BridgeMessageType.approvalRequired) {
        try {
          final toolCall = _parseToolCall(msg.payload);
          state = [...state, toolCall];
        } catch (_) {
          // Malformed payload — ignore.
        }
      }
    });
  }

  ToolCall _parseToolCall(Map<String, dynamic> payload) {
    final params = <String, dynamic>{
      ...((payload['params'] as Map<String, dynamic>?) ?? {}),
    };
    final source = payload['source'] as String? ?? 'agent_sdk';
    if (source.isNotEmpty) {
      params[observedHookSourceKey] = source;
    }

    return ToolCall(
      id: payload['tool_call_id'] as String? ?? _uuid.v4(),
      sessionId: payload['session_id'] as String? ?? '',
      tool: payload['tool'] as String? ?? 'unknown',
      params: params,
      description: payload['description'] as String?,
      reasoning: payload['reasoning'] as String?,
      riskLevel: _parseRisk(payload['risk_level'] as String?),
      decision: ApprovalDecision.pending,
      createdAt: DateTime.now(),
    );
  }

  RiskLevel _parseRisk(String? value) {
    return switch (value) {
      'medium' => RiskLevel.medium,
      'high' => RiskLevel.high,
      'critical' => RiskLevel.critical,
      _ => RiskLevel.low,
    };
  }

  Future<void> approve(String sessionId, String toolCallId) async {
    final pending = _pendingToolCall(toolCallId);
    if (pending == null || isObservedHookApproval(pending)) {
      return;
    }

    await _sendDecision(sessionId, toolCallId, 'approved');
    await _persist(toolCallId, ApprovalDecision.approved);
    _remove(toolCallId);
  }

  Future<void> reject(String sessionId, String toolCallId) async {
    final pending = _pendingToolCall(toolCallId);
    if (pending == null || isObservedHookApproval(pending)) {
      return;
    }

    await _sendDecision(sessionId, toolCallId, 'rejected');
    await _persist(toolCallId, ApprovalDecision.rejected);
    _remove(toolCallId);
  }

  Future<void> modify(
    String sessionId,
    String toolCallId,
    Map<String, dynamic> modifications,
  ) async {
    final pending = _pendingToolCall(toolCallId);
    if (pending == null || isObservedHookApproval(pending)) {
      return;
    }

    final service = _ref.read(webSocketServiceProvider);
    service.send(BridgeMessage.approvalResponse(
      sessionId: sessionId,
      toolCallId: toolCallId,
      decision: 'modified',
      modifications: modifications,
    ));
    await _persist(toolCallId, ApprovalDecision.modified,
        modifications: jsonEncode(modifications));
    _remove(toolCallId);
  }

  ToolCall? _pendingToolCall(String toolCallId) {
    try {
      return state.firstWhere((toolCall) => toolCall.id == toolCallId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendDecision(
      String sessionId, String toolCallId, String decision) async {
    final service = _ref.read(webSocketServiceProvider);
    service.send(BridgeMessage.approvalResponse(
      sessionId: sessionId,
      toolCallId: toolCallId,
      decision: decision,
    ));
  }

  Future<void> _persist(
    String toolCallId,
    ApprovalDecision decision, {
    String? modifications,
  }) async {
    final db = _ref.read(databaseProvider);
    final pending = state.where((t) => t.id == toolCallId).firstOrNull;
    if (pending == null) return;

    await db.into(db.approvals).insertOnConflictUpdate(
          ApprovalsCompanion(
            id: Value(pending.id),
            sessionId: Value(pending.sessionId),
            tool: Value(pending.tool),
            description: Value(pending.description ?? ''),
            params: Value(jsonEncode(pending.params)),
            reasoning: Value(pending.reasoning),
            riskLevel: Value(pending.riskLevel.name),
            decision: Value(decision.name),
            modifications: Value(modifications),
            createdAt: Value(pending.createdAt),
            decidedAt: Value(DateTime.now()),
          ),
        );
  }

  void _remove(String toolCallId) {
    state = state.where((t) => t.id != toolCallId).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final pendingApprovalsProvider =
    StateNotifierProvider<PendingApprovalsNotifier, List<ToolCall>>((ref) {
  return PendingApprovalsNotifier(ref);
});

// ---------------------------------------------------------------------------
// Approval history (stream from DB)
// ---------------------------------------------------------------------------

final approvalHistoryProvider = StreamProvider<List<ToolCall>>((ref) {
  final db = ref.watch(databaseProvider);
  return db
      .select(db.approvals)
      .watch()
      .map((rows) => rows.map(_rowToToolCall).toList());
});

ToolCall _rowToToolCall(dynamic row) {
  Map<String, dynamic> params = {};
  try {
    params = jsonDecode(row.params as String) as Map<String, dynamic>;
  } catch (_) {}

  Map<String, dynamic>? result;
  if (row.result != null) {
    try {
      result = jsonDecode(row.result as String) as Map<String, dynamic>;
    } catch (_) {}
  }

  return ToolCall(
    id: row.id as String,
    sessionId: row.sessionId as String,
    tool: row.tool as String,
    params: params,
    description: row.description as String?,
    reasoning: row.reasoning as String?,
    riskLevel: _parseRiskLevel(row.riskLevel as String),
    decision: _parseDecision(row.decision as String),
    modifications: row.modifications as String?,
    result: result,
    createdAt: row.createdAt as DateTime,
    decidedAt: row.decidedAt as DateTime?,
  );
}

RiskLevel _parseRiskLevel(String v) {
  return RiskLevel.values.firstWhere(
    (e) => e.name == v,
    orElse: () => RiskLevel.low,
  );
}

ApprovalDecision _parseDecision(String v) {
  return ApprovalDecision.values.firstWhere(
    (e) => e.name == v,
    orElse: () => ApprovalDecision.pending,
  );
}
