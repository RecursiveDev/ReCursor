import 'package:flutter/material.dart';

import '../../../../core/models/git_models.dart';

/// Card showing branch name, ahead/behind chip counts, and a clean/dirty badge.
class GitStatusCard extends StatelessWidget {
  final GitStatus status;

  const GitStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.account_tree_outlined,
                size: 18, color: Color(0xFF569CD6)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.branch,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4D4D4),
                ),
              ),
            ),
            if (status.ahead > 0) ...[
              _Chip(
                label: '↑ ${status.ahead}',
                color: const Color(0xFF4EC9B0),
              ),
              const SizedBox(width: 6),
            ],
            if (status.behind > 0) ...[
              _Chip(
                label: '↓ ${status.behind}',
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(width: 6),
            ],
            _Chip(
              label: status.isClean ? 'Clean' : 'Dirty',
              color: status.isClean
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44747),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
