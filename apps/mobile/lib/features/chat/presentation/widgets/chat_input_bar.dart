import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/bridge_socket.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final String sessionId;
  final void Function(String) onSend;
  final VoidCallback onVoice;

  const ChatInputBar({
    super.key,
    required this.sessionId,
    required this.onSend,
    required this.onVoice,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final newHasText = _controller.text.trim().isNotEmpty;
      if (newHasText != _hasText) {
        setState(() => _hasText = newHasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final socketState = ref.watch(bridgeSocketStateProvider).valueOrNull;
    final isConnected = socketState == ConnectionStatus.connected;
    final isReconnecting = socketState == ConnectionStatus.reconnecting;

    return Container(
      color: const Color(0xFF252526),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.orange.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(
                    isReconnecting ? Icons.wifi_find : Icons.wifi_off,
                    size: 12,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isReconnecting
                          ? 'Reconnecting — messages will queue locally'
                          : 'Offline — messages will send when reconnected',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Semantics(
                label: 'Voice input',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Color(0xFF9CDCFE)),
                  onPressed: widget.onVoice,
                  tooltip: 'Voice input',
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'Message input',
                  textField: true,
                  child: TextField(
                    controller: _controller,
                    maxLines: 8,
                    minLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3C),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      counterText: _controller.text.length > 200
                          ? '${_controller.text.length} chars'
                          : null,
                      counterStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedOpacity(
                opacity: _hasText ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: Semantics(
                  label: isConnected ? 'Send message' : 'Queue message',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      isConnected ? Icons.send : Icons.schedule_send,
                      color:
                          isConnected ? const Color(0xFF569CD6) : Colors.orange,
                    ),
                    onPressed: _hasText ? _send : null,
                    tooltip: isConnected ? 'Send' : 'Queue message',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
