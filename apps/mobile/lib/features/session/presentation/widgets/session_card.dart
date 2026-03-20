import 'package:flutter/material.dart';

import '../../../../core/models/session_models.dart';
import '../../../../shared/utils/date_formatter.dart';

/// A list card summarising a [ChatSession].
class SessionCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
  });

  Widget _agentChip(String agentType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3E3E3E)),
      ),
      child: Text(
        agentType,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Widget _branchChip(String branch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF569CD6).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alt_route, size: 10, color: Color(0xFF569CD6)),
          const SizedBox(width: 3),
          Text(
            branch,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF569CD6),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SessionStatus status) {
    return switch (status) {
      SessionStatus.active => const Color(0xFF4CAF50),
      SessionStatus.paused => const Color(0xFFFF9800),
      SessionStatus.closed => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    final title = session.title.isEmpty ? 'Session' : session.title;
    final lastActivity =
        session.lastMessageAt ?? session.updatedAt ?? session.createdAt;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Leading: agent type chip
              _agentChip(session.agentType),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD4D4D4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatRelative(lastActivity),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                        if (session.branch != null) ...[
                          const SizedBox(width: 8),
                          _branchChip(session.branch!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Trailing: status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor(session.status),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
