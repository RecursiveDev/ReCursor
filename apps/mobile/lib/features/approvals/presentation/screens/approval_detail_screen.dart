import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/message_models.dart';
import '../../domain/providers/approval_provider.dart';
import '../widgets/modification_editor.dart';

/// Full-screen detail view for a pending [ToolCall] approval.
///
/// Route: `/approval/:id`
class ApprovalDetailScreen extends ConsumerStatefulWidget {
  final String toolCallId;

  const ApprovalDetailScreen({super.key, required this.toolCallId});

  @override
  ConsumerState<ApprovalDetailScreen> createState() =>
      _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState
    extends ConsumerState<ApprovalDetailScreen> {
  final _modController = TextEditingController();
  bool _showModEditor = false;

  @override
  void dispose() {
    _modController.dispose();
    super.dispose();
  }

  ToolCall? _findToolCall(List<ToolCall> list) {
    try {
      return list.firstWhere((t) => t.id == widget.toolCallId);
    } catch (_) {
      return null;
    }
  }

  Color _riskColor(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => const Color(0xFF4CAF50),
      RiskLevel.medium => const Color(0xFFFF9800),
      RiskLevel.high => const Color(0xFFF44747),
      RiskLevel.critical => const Color(0xFF8B0000),
    };
  }

  void _approve(ToolCall toolCall) {
    ref
        .read(pendingApprovalsProvider.notifier)
        .approve(toolCall.sessionId, toolCall.id);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Approved')),
    );
  }

  void _reject(ToolCall toolCall) {
    ref
        .read(pendingApprovalsProvider.notifier)
        .reject(toolCall.sessionId, toolCall.id);
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rejected')),
    );
  }

  void _submitModifications(ToolCall toolCall) {
    final text = _modController.text.trim();
    if (text.isEmpty) return;
    ref.read(pendingApprovalsProvider.notifier).modify(
          toolCall.sessionId,
          toolCall.id,
          {'instructions': text},
        );
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifications submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingApprovalsProvider);
    final toolCall = _findToolCall(pending);

    if (toolCall == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approval')),
        body: const Center(child: Text('Approval not found or already decided.')),
      );
    }

    final riskColor = _riskColor(toolCall.riskLevel);

    return Scaffold(
      appBar: AppBar(title: Text(toolCall.tool)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Risk badge + description
          Row(
            children: [
              _RiskBadge(level: toolCall.riskLevel, color: riskColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  toolCall.description ?? 'No description provided.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD4D4D4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Parameters expandable card
          _ExpandableSection(
            title: 'Parameters',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                const JsonEncoder.withIndent('  ')
                    .convert(toolCall.params),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: Color(0xFFD4D4D4),
                ),
              ),
            ),
          ),

          // Reasoning expandable card (if available)
          if (toolCall.reasoning != null) ...[
            const SizedBox(height: 8),
            _ExpandableSection(
              title: 'Reasoning',
              child: Text(
                toolCall.reasoning!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],

          // Modification editor (shown after tapping Modify)
          if (_showModEditor) ...[
            const SizedBox(height: 16),
            ModificationEditor(
              controller: _modController,
              onSubmit: () => _submitModifications(toolCall),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approve(toolCall),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _reject(toolCall),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF44747),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _showModEditor = !_showModEditor;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Modify'),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;

  const _ExpandableSection({required this.title, required this.child});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD4D4D4),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: const Color(0xFF9E9E9E),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
