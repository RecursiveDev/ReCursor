import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/session_models.dart';
import '../../domain/providers/session_timeline_provider.dart';
import '../widgets/session_timeline.dart';

/// Displays the detail view for a single [ChatSession].
///
/// Shows a stats row (message count, tool-use count, duration) at the top,
/// followed by the session [SessionTimeline].
class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;
  final String? sessionTitle;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    this.sessionTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(sessionEventsProvider(sessionId));

    final messageCount = events
        .where((e) =>
            e.eventType == SessionEventType.userMessage ||
            e.eventType == SessionEventType.agentMessage)
        .length;

    final toolUseCount =
        events.where((e) => e.eventType == SessionEventType.toolUse).length;

    Duration? duration;
    if (events.isNotEmpty) {
      duration = events.last.timestamp.difference(events.first.timestamp);
    }

    final title = (sessionTitle != null && sessionTitle!.isNotEmpty)
        ? sessionTitle!
        : 'Session';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          _StatsRow(
            messageCount: messageCount,
            toolUseCount: toolUseCount,
            duration: duration,
          ),
          const Divider(height: 1),
          Expanded(
            child: SessionTimeline(events: events),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int messageCount;
  final int toolUseCount;
  final Duration? duration;

  const _StatsRow({
    required this.messageCount,
    required this.toolUseCount,
    required this.duration,
  });

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.chat_bubble_outline,
            value: '$messageCount',
            label: 'Messages',
          ),
          _StatItem(
            icon: Icons.build_outlined,
            value: '$toolUseCount',
            label: 'Tool Uses',
          ),
          _StatItem(
            icon: Icons.timer_outlined,
            value: duration != null ? _formatDuration(duration!) : '—',
            label: 'Duration',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD4D4D4),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
