// Simple event analytics — no external SDK, logs locally and optionally to a self-hosted endpoint
// User must opt in (checked against AppPreferences)

import 'package:flutter/foundation.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;

  const AnalyticsEvent({required this.name, this.properties = const {}, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'name': name,
    'properties': properties,
    'timestamp': timestamp.toIso8601String(),
  };
}

class AnalyticsService {
  static bool _enabled = false;
  static final List<AnalyticsEvent> _buffer = [];
  static const int _maxBuffer = 100;

  static void setEnabled(bool enabled) { _enabled = enabled; }
  static bool get isEnabled => _enabled;

  static void track(String event, {Map<String, dynamic>? properties}) {
    if (!_enabled) return;
    final e = AnalyticsEvent(name: event, properties: properties ?? {}, timestamp: DateTime.now());
    _buffer.add(e);
    if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
    debugPrint('[Analytics] $event ${properties ?? {}}');
  }

  // Pre-defined events
  static void trackSessionStarted(String agentType) => track('session_started', properties: {'agent_type': agentType});
  static void trackMessageSent() => track('message_sent');
  static void trackApprovalDecision(String decision) => track('approval_decision', properties: {'decision': decision});
  static void trackToolCardExpanded(String tool) => track('tool_card_expanded', properties: {'tool': tool});
  static void trackDiffViewed() => track('diff_viewed');
  static void trackVoiceInputUsed() => track('voice_input_used');
  static void trackAgentAdded(String type) => track('agent_added', properties: {'type': type});

  static List<AnalyticsEvent> get buffer => List.unmodifiable(_buffer);
  static void clearBuffer() => _buffer.clear();
}
