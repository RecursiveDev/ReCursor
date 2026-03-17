import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/session_models.dart';
import '../../domain/providers/session_provider.dart';

class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(activeSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: const Text('Sessions'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAgentPicker(context, ref),
        backgroundColor: const Color(0xFF569CD6),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
      body: sessionsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
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
                'No active sessions.\nTap + to start one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(activeSessionsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) =>
                  _SessionTile(session: sessions[i]),
            ),
          );
        },
      ),
    );
  }

  void _showAgentPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF252526),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AgentPickerSheet(),
    );
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
          session.title.isNotEmpty ? session.title : 'Session ${session.id.substring(0, 8)}',
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          session.workingDirectory,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeLabel, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
        title: const Text('Delete Session', style: TextStyle(color: Colors.white)),
        content: const Text('Remove this session and all its messages?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(activeSessionsProvider.notifier).deleteSession(session.id);
    }
  }
}

class _AgentPickerSheet extends ConsumerWidget {
  const _AgentPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pick Agent Type',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect a bridge agent first from Settings → Agents.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/settings/agents');
            },
            child: const Text('Go to Agent Settings',
                style: TextStyle(color: Color(0xFF569CD6))),
          ),
        ],
      ),
    );
  }
}
