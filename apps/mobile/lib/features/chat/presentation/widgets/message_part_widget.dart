import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/models/message_models.dart';
import 'tool_card.dart';

class MessagePartWidget extends StatelessWidget {
  final MessagePart part;
  const MessagePartWidget({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    return part.when(
      text: (content) => MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: Colors.white, height: 1.4),
          code: const TextStyle(
            fontFamily: 'JetBrainsMono',
            color: Color(0xFF9CDCFE),
            backgroundColor: Color(0xFF1E1E1E),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(6),
          ),
          h1: const TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.bold),
          h2: const TextStyle(color: Color(0xFF569CD6), fontWeight: FontWeight.bold),
          h3: const TextStyle(color: Color(0xFF569CD6)),
          blockquote: const TextStyle(color: Color(0xFF9CDCFE)),
          listBullet: const TextStyle(color: Colors.grey),
        ),
      ),
      toolUse: (tool, params, id) => ToolCard(
        toolName: tool,
        params: params,
        id: id,
        isCompleted: false,
      ),
      toolResult: (toolCallId, result) => ToolCard(
        toolName: toolCallId,
        params: const {},
        id: toolCallId,
        isCompleted: true,
        result: result,
      ),
      thinking: (content) => _ThinkingBlock(content: content),
    );
  }
}

class _ThinkingBlock extends StatefulWidget {
  final String content;
  const _ThinkingBlock({required this.content});

  @override
  State<_ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<_ThinkingBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: const Color(0xFF3C3C3C)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                const Text(
                  'Thinking...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                widget.content,
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
