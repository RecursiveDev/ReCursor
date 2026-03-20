import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/git_models.dart';
import '../../domain/providers/git_provider.dart';

/// Commit screen: compose a commit message and select which changed files
/// to include in the commit.
class CommitScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final List<GitFileChange> changes;

  const CommitScreen({
    super.key,
    required this.sessionId,
    required this.changes,
  });

  @override
  ConsumerState<CommitScreen> createState() => _CommitScreenState();
}

class _CommitScreenState extends ConsumerState<CommitScreen> {
  final _messageController = TextEditingController();
  late final List<bool> _checked;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.changes.length, true);
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _canCommit =>
      _messageController.text.trim().isNotEmpty && !_isCommitting;

  Future<void> _commit() async {
    if (!_canCommit) return;
    setState(() => _isCommitting = true);

    final selectedFiles = <String>[];
    for (var i = 0; i < widget.changes.length; i++) {
      if (_checked[i]) selectedFiles.add(widget.changes[i].path);
    }

    await ref
        .read(gitStatusProvider(widget.sessionId).notifier)
        .commit(
          widget.sessionId,
          _messageController.text.trim(),
          selectedFiles.isEmpty ? null : selectedFiles,
        );

    if (mounted) {
      setState(() => _isCommitting = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commit sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commit'),
        actions: [
          TextButton(
            onPressed: _canCommit ? _commit : null,
            child: _isCommitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Commit'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Commit message…',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widget.changes.length,
              itemBuilder: (context, index) {
                final change = widget.changes[index];
                return CheckboxListTile(
                  dense: true,
                  value: _checked[index],
                  onChanged: (v) =>
                      setState(() => _checked[index] = v ?? false),
                  title: Text(
                    change.path,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'JetBrainsMono',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
