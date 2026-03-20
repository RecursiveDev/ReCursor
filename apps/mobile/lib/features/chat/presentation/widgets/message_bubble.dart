import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/message_models.dart';
import 'message_part_widget.dart';
import 'streaming_text.dart';

class MessageBubble extends StatelessWidget {
  final Message? message;
  final bool isStreaming;
  final String? streamingSessionId;
  final String? streamingText;

  const MessageBubble({
    super.key,
    required Message this.message,
  })  : isStreaming = false,
        streamingSessionId = null,
        streamingText = null;

  const MessageBubble.streaming({
    super.key,
    required String sessionId,
    required String text,
  })  : message = null,
        isStreaming = true,
        streamingSessionId = sessionId,
        streamingText = text;

  @override
  Widget build(BuildContext context) {
    if (isStreaming) {
      return _BubbleLayout(
        isUser: false,
        timestamp: null,
        child: StreamingText(text: streamingText ?? '', isStreaming: true),
      );
    }

    final msg = message!;
    final isUser = msg.role == MessageRole.user;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: GestureDetector(
        onLongPress: () => _showTimestamp(context, msg.createdAt),
        child: _BubbleLayout(
          isUser: isUser,
          timestamp: null,
          child: isUser
              ? Text(
                  msg.content,
                  style: const TextStyle(color: Colors.white),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: msg.parts
                      .map((p) => MessagePartWidget(
                            part: p,
                            metadata: msg.metadata,
                          ))
                      .toList(),
                ),
        ),
      ),
    );
  }

  void _showTimestamp(BuildContext context, DateTime ts) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(DateFormat('MMM d, y HH:mm:ss').format(ts)),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF3C3C3C),
      ),
    );
  }
}

class _BubbleLayout extends StatelessWidget {
  final bool isUser;
  final DateTime? timestamp;
  final Widget child;

  const _BubbleLayout({
    required this.isUser,
    required this.timestamp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF569CD6) : const Color(0xFF252526),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }
}
