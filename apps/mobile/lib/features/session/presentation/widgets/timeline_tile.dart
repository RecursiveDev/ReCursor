import 'package:flutter/material.dart';

import '../../../../core/models/session_models.dart';
import '../../../../shared/utils/date_formatter.dart';

/// A single row in the session timeline.
///
/// Renders a vertical connector + dot on the left and an [_EventCard] on the
/// right.
class TimelineTile extends StatelessWidget {
  final SessionEvent event;
  final bool isFirst;
  final bool isLast;

  const TimelineTile({
    super.key,
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  Color _dotColor(SessionEventType type) {
    return switch (type) {
      SessionEventType.userMessage => const Color(0xFF569CD6),
      SessionEventType.agentMessage => const Color(0xFF569CD6),
      SessionEventType.toolUse => const Color(0xFFFF9800),
      SessionEventType.toolResult => const Color(0xFF4EC9B0),
      SessionEventType.sessionStart => const Color(0xFF4CAF50),
      SessionEventType.sessionEnd => const Color(0xFF9E9E9E),
      SessionEventType.hookEvent => const Color(0xFFCE9178),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor(event.eventType);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: connector line + dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Top connector
                Container(
                  width: 2,
                  height: isFirst ? 8 : 20,
                  color: isFirst
                      ? Colors.transparent
                      : const Color(0xFF3E3E3E),
                ),
                // Dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                // Bottom connector
                Container(
                  width: 2,
                  height: isLast ? 8 : 30,
                  color: isLast
                      ? Colors.transparent
                      : const Color(0xFF3E3E3E),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: event card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _EventCard(event: event),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SessionEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD4D4D4),
                    ),
                  ),
                ),
                Text(
                  DateFormatter.formatTime(event.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            if (event.description != null) ...[
              const SizedBox(height: 4),
              Text(
                event.description!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
