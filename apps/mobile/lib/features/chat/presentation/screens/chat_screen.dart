import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/message_models.dart';
import '../../domain/providers/chat_provider.dart';
import '../../domain/providers/session_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_input_sheet.dart';
import 'session_list_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _syncCurrentSession();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _syncCurrentSession();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncCurrentSession() {
    final notifier = ref.read(currentSessionProvider.notifier);
    if (notifier.state != widget.sessionId) {
      notifier.state = widget.sessionId;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    ref.read(chatNotifierProvider.notifier).sendMessage(widget.sessionId, text);
    _scrollToBottom();
  }

  void _openVoice() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VoiceInputSheet(
        onSend: (text) {
          Navigator.pop(context);
          _sendMessage(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatNotifierProvider);
    final session = ref.watch(activeSessionProvider(widget.sessionId));
    final messagesAsync = ref.watch(messagesProvider(widget.sessionId));
    final streamingMap = ref.watch(streamingMessageProvider);
    final streamingText = streamingMap[widget.sessionId];

    // Auto-scroll when messages change
    ref.listen(
        messagesProvider(widget.sessionId), (_, __) => _scrollToBottom());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 720;

        if (isTablet) {
          return Row(
            children: [
              const SizedBox(
                width: 300,
                child: SessionListScreen(),
              ),
              const VerticalDivider(width: 1, color: Color(0xFF3C3C3C)),
              Expanded(
                  child: _ChatBody(
                sessionId: widget.sessionId,
                sessionTitle: session?.title ?? 'Chat',
                branch: session?.branch,
                messagesAsync: messagesAsync,
                streamingText: streamingText,
                scrollController: _scrollController,
                onSend: _sendMessage,
                onVoice: _openVoice,
              )),
            ],
          );
        }

        return _ChatBody(
          sessionId: widget.sessionId,
          sessionTitle: session?.title ?? 'Chat',
          branch: session?.branch,
          messagesAsync: messagesAsync,
          streamingText: streamingText,
          scrollController: _scrollController,
          onSend: _sendMessage,
          onVoice: _openVoice,
        );
      },
    );
  }
}

class _ChatBody extends StatelessWidget {
  final String sessionId;
  final String sessionTitle;
  final String? branch;
  final AsyncValue<List<Message>> messagesAsync;
  final String? streamingText;
  final ScrollController scrollController;
  final void Function(String) onSend;
  final VoidCallback onVoice;

  const _ChatBody({
    required this.sessionId,
    required this.sessionTitle,
    required this.branch,
    required this.messagesAsync,
    required this.streamingText,
    required this.scrollController,
    required this.onSend,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: Row(
          children: [
            Expanded(
              child: Text(
                sessionTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (branch != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3C3C3C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.call_split,
                        size: 12, color: Color(0xFF4EC9B0)),
                    const SizedBox(width: 4),
                    Text(
                      branch!,
                      style: const TextStyle(
                          color: Color(0xFF4EC9B0), fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (messages) {
                final hasStreaming =
                    streamingText != null && streamingText!.isNotEmpty;
                final itemCount = messages.length + (hasStreaming ? 1 : 0);

                if (itemCount == 0) {
                  return const Center(
                    child: Text(
                      'Start the conversation',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, i) {
                    if (i < messages.length) {
                      return MessageBubble(message: messages[i]);
                    }
                    // Streaming placeholder
                    return MessageBubble.streaming(
                        sessionId: sessionId, text: streamingText!);
                  },
                );
              },
            ),
          ),
          ChatInputBar(
            sessionId: sessionId,
            onSend: onSend,
            onVoice: onVoice,
          ),
        ],
      ),
    );
  }
}
