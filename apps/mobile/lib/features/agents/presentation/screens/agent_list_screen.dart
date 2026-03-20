import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/providers/agent_provider.dart';
import '../widgets/agent_card.dart';

/// Lists all configured agents with swipe-to-delete and an add FAB.
class AgentListScreen extends ConsumerStatefulWidget {
  const AgentListScreen({super.key});

  @override
  ConsumerState<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends ConsumerState<AgentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agentsProvider.notifier).load();
    });
  }

  Future<void> _delete(String id, String name) async {
    await ref.read(agentsProvider.notifier).delete(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name removed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Re-adding would require keeping the deleted model around;
              // for now just refresh — a full undo is a future enhancement.
              ref.read(agentsProvider.notifier).load();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/agents/config'),
        icon: const Icon(Icons.add),
        label: const Text('Add Agent'),
      ),
      body: agentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (agents) {
          if (agents.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: agents.length,
            itemBuilder: (context, index) {
              final agent = agents[index];
              return Dismissible(
                key: Key(agent.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: const Color(0xFFF44747),
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) => _delete(agent.id, agent.displayName),
                child: AgentCard(
                  agent: agent,
                  onTap: () =>
                      context.push('/home/agents/config', extra: agent),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined, size: 64, color: Color(0xFF9E9E9E)),
          SizedBox(height: 16),
          Text(
            'No agents configured',
            style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + Add Agent to get started.',
            style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}
