import 'package:flutter/material.dart';

import '../../../../core/models/message_models.dart';

class ToolCard extends StatefulWidget {
  final String toolName;
  final Map<String, dynamic> params;
  final String? id;
  final bool isCompleted;
  final ToolResult? result;

  const ToolCard({
    super.key,
    required this.toolName,
    required this.params,
    this.id,
    required this.isCompleted,
    this.result,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard>
    with SingleTickerProviderStateMixin {
  bool _paramsExpanded = false;
  bool _resultExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

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
    if (!widget.isCompleted) return const Color(0xFF569CD6);
    return (widget.result?.success ?? false)
        ? const Color(0xFF4EC9B0)
        : Colors.redAccent;
  }

  IconData get _statusIcon {
    if (!widget.isCompleted) return Icons.hourglass_empty;
    return (widget.result?.success ?? false) ? Icons.check_circle : Icons.error;
  }

  String get _statusLabel {
    if (!widget.isCompleted) return 'running';
    return (widget.result?.success ?? false) ? 'succeeded' : 'failed';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tool: ${widget.toolName}, status: $_statusLabel',
      child: Card(
      color: const Color(0xFF2D2D2D),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(_statusIcon, color: _statusColor, size: 18),
              ],
            ),
          ),
          // Params expandable
          if (widget.params.isNotEmpty)
            _ExpandableSection(
              label: 'Parameters',
              expanded: _paramsExpanded,
              onTap: () =>
                  setState(() => _paramsExpanded = !_paramsExpanded),
              child: _KeyValueList(map: widget.params),
            ),
          // Result expandable
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
        ],
      ),
    ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  final String toolName;
  const _ToolIcon({required this.toolName});

  IconData get _icon {
    final name = toolName.toLowerCase();
    if (name.contains('file') || name.contains('read') || name.contains('write')) {
      return Icons.description;
    }
    if (name.contains('bash') || name.contains('shell') || name.contains('exec')) {
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
