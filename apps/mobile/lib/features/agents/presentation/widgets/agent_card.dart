import 'package:flutter/material.dart';

import '../../../../core/models/agent_models.dart';
import '../../../../shared/utils/date_formatter.dart';

/// Card for a configured [AgentConfig] in the agent list.
class AgentCard extends StatelessWidget {
  final AgentConfig agent;
  final VoidCallback onTap;

  const AgentCard({super.key, required this.agent, required this.onTap});

  IconData _iconForType(AgentType type) {
    return switch (type) {
      AgentType.claudeCode => Icons.auto_awesome,
      AgentType.openCode => Icons.code,
      AgentType.aider => Icons.terminal,
      AgentType.goose => Icons.rocket_launch_outlined,
      AgentType.custom => Icons.settings_input_component,
    };
  }

  Color _statusColor(AgentConnectionStatus status) {
    return switch (status) {
      AgentConnectionStatus.connected => const Color(0xFF4CAF50),
      AgentConnectionStatus.inactive => const Color(0xFFFF9800),
      AgentConnectionStatus.disconnected => const Color(0xFF9E9E9E),
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(agent.status);
    final lastConnected = agent.lastConnectedAt != null
        ? DateFormatter.formatRelative(agent.lastConnectedAt!)
        : 'Never';

    // Truncate long bridge URLs.
    final bridgeDisplay = agent.bridgeUrl.length > 40
        ? '${agent.bridgeUrl.substring(0, 37)}…'
        : agent.bridgeUrl;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF252526),
            child: Icon(
              _iconForType(agent.type),
              size: 18,
              color: const Color(0xFF569CD6),
            ),
          ),
          title: Text(
            agent.displayName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD4D4D4),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bridgeDisplay,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrainsMono',
                  color: Color(0xFF9E9E9E),
                ),
              ),
              Text(
                'Last connected: $lastConnected',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          trailing: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}
