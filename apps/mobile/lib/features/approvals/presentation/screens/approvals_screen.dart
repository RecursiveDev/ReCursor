import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/message_models.dart';
import '../../domain/providers/approval_provider.dart';
import '../widgets/approval_card.dart';

/// Two-tab screen: "Pending" approvals and "History" of past decisions.
class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Approvals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending tab
// ---------------------------------------------------------------------------

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingApprovalsProvider);

    if (pending.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No pending approvals',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final toolCall = pending[index];
        return ApprovalCard(
          toolCall: toolCall,
          onApprove: () => ref
              .read(pendingApprovalsProvider.notifier)
              .approve(toolCall.sessionId, toolCall.id),
          onReject: () => ref
              .read(pendingApprovalsProvider.notifier)
              .reject(toolCall.sessionId, toolCall.id),
          onTap: () => context.push('/approval/${toolCall.id}'),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// History tab
// ---------------------------------------------------------------------------

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  Color _decisionColor(ApprovalDecision decision) {
    return switch (decision) {
      ApprovalDecision.approved => const Color(0xFF4CAF50),
      ApprovalDecision.rejected => const Color(0xFFF44747),
      ApprovalDecision.modified => const Color(0xFFFF9800),
      ApprovalDecision.pending => const Color(0xFF569CD6),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(approvalHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) {
        if (history.isEmpty) {
          return const _EmptyState(
            icon: Icons.history,
            title: 'No history yet',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final color = _decisionColor(item.decision);
            return ListTile(
              dense: true,
              leading: const Icon(Icons.build_outlined,
                  size: 18, color: Color(0xFF9E9E9E)),
              title: Text(
                item.tool,
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: item.description != null
                  ? Text(
                      item.description!,
                      style:
                          const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  item.decision.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF9E9E9E)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}
