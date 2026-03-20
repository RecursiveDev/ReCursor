import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connection_state.dart';
import '../../core/providers/websocket_provider.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider);
    return statusAsync.when(
      data: (status) => _buildBar(status),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBar(ConnectionStatus status) {
    if (status == ConnectionStatus.connected) return const SizedBox.shrink();

    final isReconnecting = status == ConnectionStatus.reconnecting;
    final color = isReconnecting
        ? const Color(0xFFFF9800)
        : const Color(0xFFF44747);
    final message = isReconnecting ? 'Reconnecting...' : 'Offline';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
