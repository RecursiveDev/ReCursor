import 'dart:async';
import 'package:flutter/material.dart';

class StreamingText extends StatefulWidget {
  final String text;
  final bool isStreaming;

  const StreamingText({
    super.key,
    required this.text,
    this.isStreaming = true,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
    _cursorOpacity =
        Tween<double>(begin: 0, end: 1).animate(_cursorController);
    if (widget.isStreaming) {
      _cursorController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StreamingText old) {
    super.didUpdateWidget(old);
    if (!old.isStreaming && widget.isStreaming) {
      _cursorController.repeat(reverse: true);
    } else if (old.isStreaming && !widget.isStreaming) {
      _cursorController.stop();
      _cursorController.value = 0;
    }
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: widget.text,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
          if (widget.isStreaming)
            WidgetSpan(
              child: FadeTransition(
                opacity: _cursorOpacity,
                child: const Text(
                  '|',
                  style: TextStyle(
                      color: Color(0xFF569CD6),
                      fontWeight: FontWeight.w100,
                      fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
