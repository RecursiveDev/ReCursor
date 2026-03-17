import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/terminal_provider.dart';
import '../widgets/terminal_output.dart';

/// Terminal emulator screen backed by a WebSocket bridge session.
class TerminalScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String workingDirectory;

  const TerminalScreen({
    super.key,
    required this.sessionId,
    this.workingDirectory = '~',
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _historyScrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  static const int _maxHistory = 50;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(terminalOutputProvider(widget.sessionId).notifier)
          .createSession(widget.sessionId, widget.workingDirectory);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _historyScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendCommand() {
    final command = _inputController.text.trim();
    if (command.isEmpty) return;
    _inputController.clear();
    _historyIndex = -1;

    // Add to history (avoid consecutive duplicates)
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      setState(() {
        _commandHistory.add(command);
        if (_commandHistory.length > _maxHistory) {
          _commandHistory.removeAt(0);
        }
      });
    }

    ref
        .read(terminalOutputProvider(widget.sessionId).notifier)
        .sendInput(widget.sessionId, command);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  void _recallHistory(int direction) {
    // direction: -1 = up (older), +1 = down (newer)
    if (_commandHistory.isEmpty) return;
    setState(() {
      _historyIndex = (_historyIndex - direction).clamp(
        -1,
        _commandHistory.length - 1,
      );
      if (_historyIndex == -1) {
        _inputController.clear();
      } else {
        final idx = _commandHistory.length - 1 - _historyIndex;
        _inputController.text = _commandHistory[idx];
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.length),
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _recallHistory(-1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _recallHistory(1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Widget _buildTerminalOutput() {
    final lines = ref.watch(terminalOutputProvider(widget.sessionId));
    return TerminalOutput(lines: lines);
  }

  Widget _buildInputBar() {
    return _InputBar(
      controller: _inputController,
      focusNode: _focusNode,
      onSend: _sendCommand,
      onKeyEvent: _handleKeyEvent,
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      controller: _historyScrollController,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _commandHistory.length,
      itemBuilder: (context, index) {
        // Show most recent at top
        final cmd = _commandHistory[_commandHistory.length - 1 - index];
        return InkWell(
          onTap: () {
            _inputController.text = cmd;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: cmd.length),
            );
            _focusNode.requestFocus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              cmd,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                color: Color(0xFFD4D4D4),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auto-scroll when new lines arrive.
    ref.listen(terminalOutputProvider(widget.sessionId), (_, __) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom());
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Terminal',
                style: TextStyle(fontSize: 15, color: Color(0xFFD4D4D4))),
            Text(
              widget.workingDirectory,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > 600;

          if (isLandscape) {
            return Row(
              children: [
                // Left 60%: terminal output
                Flexible(
                  flex: 60,
                  child: Column(
                    children: [
                      Expanded(child: _buildTerminalOutput()),
                    ],
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  color: Color(0xFF30363D),
                ),
                // Right 40%: command history + input at bottom
                Flexible(
                  flex: 40,
                  child: Container(
                    color: const Color(0xFF0D1117),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: const Color(0xFF161B22),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          width: double.infinity,
                          child: const Text(
                            'History',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                        ),
                        Expanded(child: _buildHistoryList()),
                        const Divider(height: 1, color: Color(0xFF30363D)),
                        _buildInputBar(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          // Portrait layout
          return Column(
            children: [
              Expanded(child: _buildTerminalOutput()),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text(
            '\$',
            style: TextStyle(
              color: Color(0xFF4EC9B0),
              fontFamily: 'JetBrainsMono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Focus(
              focusNode: focusNode,
              onKeyEvent: onKeyEvent,
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  color: Color(0xFFD4D4D4),
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Enter command…',
                  hintStyle: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
                  filled: false,
                ),
                onSubmitted: (_) => onSend(),
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send, size: 18),
            color: const Color(0xFF569CD6),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
