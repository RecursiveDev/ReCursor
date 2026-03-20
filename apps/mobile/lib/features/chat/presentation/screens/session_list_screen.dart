import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/session_models.dart';
import '../../../../core/network/connection_state.dart';
import '../../../../core/providers/bridge_provider.dart';
import '../../domain/providers/chat_provider.dart';
import '../../domain/providers/session_provider.dart';

class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(chatNotifierProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: const Text('Sessions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewSessionSheet(context, ref),
        backgroundColor: const Color(0xFF569CD6),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                'No sessions yet.\nTap + to start a Claude Code Agent SDK session.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(activeSessionsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _SessionTile(session: sessions[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNewSessionSheet(BuildContext context, WidgetRef ref) async {
    final sessionId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF252526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NewSessionSheet(),
    );

    if (sessionId != null && context.mounted) {
      ref.read(currentSessionProvider.notifier).state = sessionId;
      context.go('/home/chat/$sessionId');
    }
  }
}

class _SessionTile extends ConsumerWidget {
  final ChatSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLabel = session.lastMessageAt != null
        ? DateFormat.jm().format(session.lastMessageAt!)
        : '';
    final statusColor = switch (session.status) {
      SessionStatus.active => const Color(0xFF4EC9B0),
      SessionStatus.paused => Colors.orange,
      SessionStatus.closed => Colors.grey,
    };

    return GestureDetector(
      onLongPress: () => _confirmDelete(context, ref),
      child: ListTile(
        tileColor: const Color(0xFF252526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3C3C3C),
          child: Text(
            session.agentType.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Color(0xFF569CD6)),
          ),
        ),
        title: Text(
          session.title.isNotEmpty
              ? session.title
              : 'Session ${session.id.substring(0, 8)}',
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          session.workingDirectory.isEmpty
              ? 'Waiting for bridge details'
              : session.workingDirectory,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeLabel,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        onTap: () {
          ref.read(currentSessionProvider.notifier).state = session.id;
          context.go('/home/chat/${session.id}');
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF252526),
        title: const Text(
          'Delete Session',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Remove this session and all its messages?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(activeSessionsProvider.notifier).deleteSession(session.id);
    }
  }
}

class _NewSessionSheet extends ConsumerStatefulWidget {
  const _NewSessionSheet();

  @override
  ConsumerState<_NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends ConsumerState<_NewSessionSheet> {
  final TextEditingController _workingDirectoryController =
      TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _workingDirectoryController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    final workingDirectory = _workingDirectoryController.text.trim();
    if (workingDirectory.isEmpty) {
      setState(() {
        _error = 'Working directory is required.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final sessionId = await ref
          .read(chatNotifierProvider.notifier)
          .startSession('claude-code', workingDirectory);
      if (mounted) {
        Navigator.of(context).pop(sessionId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bridgeStatus = ref.watch(bridgeProvider);
    final isConnected = bridgeStatus == ConnectionStatus.connected;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start Claude Code Session',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isConnected
                ? 'This starts a parallel Agent SDK session on the connected bridge.'
                : 'Bridge is offline. The session start request will queue locally and send after reconnect.',
            style: TextStyle(
              color: isConnected ? const Color(0xFF9CDCFE) : Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('newSessionWorkingDirectoryField'),
            controller: _workingDirectoryController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Working Directory',
              labelStyle: const TextStyle(color: Color(0xFF9CDCFE)),
              hintText: '/Users/me/project',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitting ? null : _startSession(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _startSession,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isConnected ? Icons.play_arrow : Icons.schedule_send),
            label: Text(isConnected ? 'Start Session' : 'Queue Session Start'),
          ),
        ],
      ),
    );
  }
}
