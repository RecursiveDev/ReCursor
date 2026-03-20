import 'package:flutter/material.dart';

import '../../../../core/models/message_models.dart';
import '../../domain/approval_source.dart';

/// Card widget representing a pending tool-call approval.
class ApprovalCard extends StatelessWidget {
  final ToolCall toolCall;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const ApprovalCard({
    super.key,
    required this.toolCall,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  Color _riskColor(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => const Color(0xFF4CAF50),
      RiskLevel.medium => const Color(0xFFFF9800),
      RiskLevel.high => const Color(0xFFF44747),
      RiskLevel.critical => const Color(0xFF8B0000),
    };
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(toolCall.riskLevel);
    final isObservedHook = isObservedHookApproval(toolCall);

    return Semantics(
      label:
          'Tool approval: ${toolCall.tool}, risk: ${toolCall.riskLevel.name}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: tool icon + name + risk badge
                Row(
                  children: [
                    const Icon(Icons.build_outlined,
                        size: 16, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        toolCall.tool,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4D4D4),
                        ),
                      ),
                    ),
                    _RiskBadge(level: toolCall.riskLevel, color: riskColor),
                  ],
                ),
                if (toolCall.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    toolCall.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                if (isObservedHook) ...[
                  const Text(
                    'Observed via Claude hooks — action buttons are available only for bridge-side Agent SDK sessions.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (!isObservedHook) ...[
                      Expanded(
                        child: Semantics(
                          label: 'Approve tool call',
                          button: true,
                          child: OutlinedButton(
                            onPressed: onApprove,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4CAF50),
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            child: const Text('Approve',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          label: 'Reject tool call',
                          button: true,
                          child: OutlinedButton(
                            onPressed: onReject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF44747),
                              side: const BorderSide(color: Color(0xFFF44747)),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            child: const Text('Reject',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        isObservedHook ? 'View' : 'Details',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final Color color;

  const _RiskBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
