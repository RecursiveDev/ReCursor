import 'package:flutter/material.dart';

/// Conflict resolution strategies for offline sync.
class ConflictResolver {
  const ConflictResolver();

  /// Last-write-wins: return whichever record has the later [updatedAt].
  /// If both are equal, prefer [remote].
  T resolve<T extends _HasUpdatedAt>(T local, T remote) {
    if (local.updatedAt == null) return remote;
    if (remote.updatedAt == null) return local;
    return local.updatedAt!.isAfter(remote.updatedAt!) ? local : remote;
  }

  /// Show a dialog asking the user which version to keep.
  /// Returns the chosen record.
  Future<T> resolveWithUserPrompt<T extends _HasUpdatedAt>(
    T local,
    T remote,
    BuildContext context,
  ) async {
    final choice = await showDialog<_ConflictChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Sync Conflict'),
        content: const Text(
          'This item was modified both locally and on the server. '
          'Which version would you like to keep?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ConflictChoice.local),
            child: const Text('Keep Mine'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ConflictChoice.remote),
            child: const Text('Use Server Version'),
          ),
        ],
      ),
    );

    return switch (choice) {
      _ConflictChoice.local => local,
      _ => remote,
    };
  }
}

enum _ConflictChoice { local, remote }

/// Mixin contract for types that expose an [updatedAt] timestamp.
abstract interface class _HasUpdatedAt {
  DateTime? get updatedAt;
}
