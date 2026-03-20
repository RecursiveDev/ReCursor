import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/message_models.dart';
import '../../../diff/domain/providers/diff_provider.dart';

/// Visual state of a tool card in the chat timeline.
enum ToolState {
  /// Tool is pending user approval.
  pendingApproval,

  /// Tool is executing (running).
  running,

  /// Tool completed successfully.
  completed,

  /// Tool failed.
  failed,
}

class ToolCard extends ConsumerStatefulWidget {
  final String toolName;
  final Map<String, dynamic> params;
  final String? id;
  final bool isCompleted;
  final ToolResult? result;

  /// Optional metadata from parent message (contains approval state like 'risk_level').
  final Map<String, dynamic>? metadata;

  const ToolCard({
    super.key,
    required this.toolName,
    required this.params,
    this.id,
    required this.isCompleted,
    this.result,
    this.metadata,
  });

  @override
  ConsumerState<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends ConsumerState<ToolCard>
    with SingleTickerProviderStateMixin {
  bool _paramsExpanded = false;
  bool _resultExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  /// Determines the visual state of this tool card.
  ToolState get _state {
    final riskLevel = widget.metadata?['risk_level'] as String?;
    if (riskLevel != null && !widget.isCompleted) {
      return ToolState.pendingApproval;
    }
    if (!widget.isCompleted) return ToolState.running;
    if (widget.result?.success ?? false) return ToolState.completed;
    return ToolState.failed;
  }

  RiskLevel get _riskLevel {
    final level = widget.metadata?['risk_level'] as String?;
    return switch (level) {
      'medium' => RiskLevel.medium,
      'high' => RiskLevel.high,
      'critical' => RiskLevel.critical,
      _ => RiskLevel.low,
    };
  }

  String? get _source {
    final metadataSource = widget.metadata?['source'];
    if (metadataSource is String && metadataSource.isNotEmpty) {
      return metadataSource;
    }

    final resultSource = widget.result?.metadata?['source'];
    if (resultSource is String && resultSource.isNotEmpty) {
      return resultSource;
    }

    return null;
  }

  String? get _diffText {
    final diff = widget.result?.metadata?['diff'];
    if (diff is String && diff.trim().isNotEmpty) {
      return diff;
    }
    return null;
  }

  bool get _hasDiff => _diffText != null;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    if (widget.isCompleted) _expandController.forward();
  }

  @override
  void didUpdateWidget(ToolCard old) {
    super.didUpdateWidget(old);
    if (!old.isCompleted && widget.isCompleted) {
      _expandController.forward();
      setState(() => _resultExpanded = true);
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    return switch (_state) {
      ToolState.pendingApproval => _riskBadgeColor,
      ToolState.running => const Color(0xFF569CD6),
      ToolState.completed => const Color(0xFF4EC9B0),
      ToolState.failed => Colors.redAccent,
    };
  }

  Color get _riskBadgeColor {
    return switch (_riskLevel) {
      RiskLevel.low => const Color(0xFF4CAF50),
      RiskLevel.medium => const Color(0xFFFF9800),
      RiskLevel.high => const Color(0xFFF44747),
      RiskLevel.critical => const Color(0xFF8B0000),
    };
  }

  IconData get _statusIcon {
    return switch (_state) {
      ToolState.pendingApproval => Icons.pending_actions,
      ToolState.running => Icons.hourglass_empty,
      ToolState.completed => Icons.check_circle,
      ToolState.failed => Icons.error,
    };
  }

  String get _statusLabel {
    return switch (_state) {
      ToolState.pendingApproval => 'approval required',
      ToolState.running => 'running',
      ToolState.completed => 'succeeded',
      ToolState.failed => 'failed',
    };
  }

  void _openDiff() {
    final diffText = _diffText;
    if (diffText == null) {
      return;
    }

    final opened =
        ref.read(diffNotifierProvider.notifier).openUnifiedDiff(diffText);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to open diff for this tool result.')),
      );
      return;
    }

    context.go('/home/diff');
  }

  @override
  Widget build(BuildContext context) {
    final isPendingApproval = _state == ToolState.pendingApproval;

    return Semantics(
      label: 'Tool: ${widget.toolName}, status: $_statusLabel',
      child: Card(
        color: const Color(0xFF2D2D2D),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isPendingApproval
              ? BorderSide(
                  color: _riskBadgeColor.withValues(alpha: 0.5), width: 2)
              : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _ToolIcon(toolName: widget.toolName),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.toolName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPendingApproval) ...[
                    _RiskBadge(level: _riskLevel, color: _riskBadgeColor),
                    const SizedBox(width: 8),
                  ],
                  Icon(_statusIcon, color: _statusColor, size: 18),
                ],
              ),
            ),
            if (isPendingApproval)
              _ApprovalBanner(
                riskLevel: _riskLevel,
                source: _source,
              ),
            if (widget.params.isNotEmpty)
              _ExpandableSection(
                label: 'Parameters',
                expanded: _paramsExpanded,
                onTap: () => setState(() => _paramsExpanded = !_paramsExpanded),
                child: _KeyValueList(map: widget.params),
              ),
            if (widget.isCompleted && widget.result != null)
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _ExpandableSection(
                  label: 'Result',
                  expanded: _resultExpanded,
                  onTap: () =>
                      setState(() => _resultExpanded = !_resultExpanded),
                  child: _ResultContent(result: widget.result!),
                ),
              ),
            if (_hasDiff)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _openDiff,
                    icon: const Icon(Icons.difference_outlined, size: 16),
                    label: const Text('View Diff'),
                  ),
                ),
              ),
          ],
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

class _ApprovalBanner extends StatelessWidget {
  final RiskLevel riskLevel;
  final String? source;

  const _ApprovalBanner({required this.riskLevel, required this.source});

  @override
  Widget build(BuildContext context) {
    final color = switch (riskLevel) {
      RiskLevel.low => const Color(0xFF4CAF50),
      RiskLevel.medium => const Color(0xFFFF9800),
      RiskLevel.high => const Color(0xFFF44747),
      RiskLevel.critical => const Color(0xFF8B0000),
    };
    final isHookObservation = source == 'hooks';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isHookObservation
                ? Icons.visibility_outlined
                : Icons.pending_actions,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isHookObservation
                  ? 'Observed via Claude hooks — review in Approvals.'
                  : 'Approval required — check Approvals tab',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final String toolName;
  const _ToolIcon({required this.toolName});

  IconData get _icon {
    final name = toolName.toLowerCase();
    if (name.contains('file') ||
        name.contains('read') ||
        name.contains('write')) {
      return Icons.description;
    }
    if (name.contains('bash') ||
        name.contains('shell') ||
        name.contains('exec')) {
      return Icons.terminal;
    }
    if (name.contains('search') || name.contains('grep')) {
      return Icons.search;
    }
    if (name.contains('git')) return Icons.call_split;
    if (name.contains('web') || name.contains('http')) return Icons.language;
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(_icon, size: 14, color: const Color(0xFF569CD6)),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _ExpandableSection({
    required this.label,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFF3C3C3C), height: 1),
        Semantics(
          label: 'Expand tool parameters',
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono')),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: child,
          ),
      ],
    );
  }
}

class _KeyValueList extends StatelessWidget {
  final Map<String, dynamic> map;
  const _KeyValueList({required this.map});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: map.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: '${e.key}: ',
                    style: const TextStyle(
                        color: Color(0xFF9CDCFE),
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12)),
                TextSpan(
                    text: e.value.toString(),
                    style: const TextStyle(
                        color: Color(0xFFCE9178),
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ResultContent extends StatelessWidget {
  final ToolResult result;
  const _ResultContent({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.error != null)
          Text(
            result.error!,
            style: const TextStyle(
                color: Colors.redAccent,
                fontFamily: 'JetBrainsMono',
                fontSize: 12),
          )
        else
          Text(
            result.content,
            style: const TextStyle(
                color: Color(0xFF4EC9B0),
                fontFamily: 'JetBrainsMono',
                fontSize: 12),
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        if (result.durationMs != null) ...[
          const SizedBox(height: 4),
          Text(
            '${result.durationMs}ms',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
