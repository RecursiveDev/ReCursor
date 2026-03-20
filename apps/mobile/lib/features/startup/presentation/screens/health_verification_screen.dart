import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connection_state.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/providers/websocket_provider.dart';

class HealthVerificationScreen extends ConsumerStatefulWidget {
  const HealthVerificationScreen({super.key});

  @override
  ConsumerState<HealthVerificationScreen> createState() =>
      _HealthVerificationScreenState();
}

class _HealthVerificationScreenState
    extends ConsumerState<HealthVerificationScreen> {
  bool _verifying = true;
  bool _acknowledging = false;
  String? _error;
  Map<String, dynamic>? _healthPayload;

  @override
  void initState() {
    super.initState();
    unawaited(_runHealthVerification());
  }

  WebSocketService get _service => ref.read(webSocketServiceProvider);

  Map<String, dynamic> get _connectionAck =>
      _service.lastConnectionAckPayload ?? const <String, dynamic>{};

  Future<void> _runHealthVerification() async {
    if (_service.currentStatus != ConnectionStatus.connected) {
      setState(() {
        _verifying = false;
        _error = 'Bridge is not connected. Reconnect and try again.';
      });
      return;
    }

    try {
      final payload = await _service.requestHealthCheck();
      if (!mounted) {
        return;
      }
      setState(() {
        _verifying = false;
        _healthPayload = payload;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _verifying = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _acknowledgeWarning() async {
    final warningCode = _primaryWarningCode;
    if (warningCode == null) {
      return;
    }

    setState(() {
      _acknowledging = true;
      _error = null;
    });

    try {
      final payload = await _service.acknowledgeWarning(warningCode);
      if (!mounted) {
        return;
      }
      setState(() {
        _acknowledging = false;
        _healthPayload = <String, dynamic>{
          ...?_healthPayload,
          'ready': payload['ready'] ?? true,
          'requires_acknowledgment': false,
          'warnings': const <String>[],
        };
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _acknowledging = false;
        _error = error.toString();
      });
    }
  }

  String get _connectionMode => (_healthPayload?['connection_mode'] ??
      _connectionAck['connection_mode'] ??
      'secure_remote') as String;

  String get _connectionDescription =>
      (_connectionAck['connection_mode_description'] ??
          _modeDescription(_connectionMode)) as String;

  String get _bridgeUrl =>
      (_connectionAck['bridge_url'] ?? 'Unknown bridge') as String;

  List<String> get _warnings =>
      ((_healthPayload?['warnings'] as List<dynamic>?) ?? const <dynamic>[])
          .map((warning) => warning.toString())
          .toList(growable: false);

  String? get _primaryWarningCode => _warnings.isEmpty ? null : _warnings.first;

  bool get _requiresAcknowledgment =>
      (_healthPayload?['requires_acknowledgment'] ?? false) == true;

  bool get _ready => (_healthPayload?['ready'] ?? false) == true;

  Map<String, dynamic> get _checks =>
      (_healthPayload?['checks'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};

  void _cancelConnection() {
    _service.disconnect();
    if (mounted) {
      context.go('/bridge-setup');
    }
  }

  void _enterApp() {
    context.go('/home/chat');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: const Text('Health Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_verifying) ...[
                const SizedBox(height: 32),
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF569CD6)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verifying bridge health and security…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else if (_requiresAcknowledgment) ...[
                const _StatusCard(
                  icon: Icons.warning_amber_rounded,
                  iconColor: Color(0xFFFFC107),
                  title: 'Direct Public Connection',
                  subtitle:
                      'This bridge is reachable over the public internet without a secure tunnel.',
                ),
                const SizedBox(height: 16),
                _ConnectionModeCard(
                  mode: _connectionMode,
                  description: _connectionDescription,
                  bridgeUrl: _bridgeUrl,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Risks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const _RiskBullet(
                    text: 'Traffic is crossing the public internet'),
                const _RiskBullet(text: 'Certificate validation must succeed'),
                const _RiskBullet(text: 'Verify the bridge endpoint is yours'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _acknowledging ? null : _acknowledgeWarning,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF569CD6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _acknowledging
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('I understand the risks'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _cancelConnection,
                  child: const Text('Cancel Connection'),
                ),
              ] else if (_ready) ...[
                const _StatusCard(
                  icon: Icons.check_circle_outline,
                  iconColor: Color(0xFF4CAF50),
                  title: 'Connection Verified',
                  subtitle:
                      'The bridge completed the required health and security checks.',
                ),
                const SizedBox(height: 16),
                _ConnectionModeCard(
                  mode: _connectionMode,
                  description: _connectionDescription,
                  bridgeUrl: _bridgeUrl,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252526),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health Checks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CheckRow(
                        label: 'TLS certificate valid',
                        passed: (_checks['tls_valid'] ?? false) == true,
                      ),
                      _CheckRow(
                        label: 'Clock synchronized',
                        passed: (_checks['clock_sync'] ?? false) == true,
                      ),
                      _CheckRow(
                        label: 'Bridge version compatible',
                        passed:
                            (_checks['version_compatible'] ?? false) == true,
                      ),
                      _CheckRow(
                        label: 'Token permissions verified',
                        passed: (_checks['token_permissions'] ?? false) == true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _enterApp,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF569CD6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Enter ReCursor'),
                ),
              ] else ...[
                _StatusCard(
                  icon: Icons.error_outline,
                  iconColor: colorScheme.error,
                  title: 'Connection Blocked',
                  subtitle: _error ??
                      'The bridge did not pass the required health checks.',
                ),
                const SizedBox(height: 16),
                _ConnectionModeCard(
                  mode: _connectionMode,
                  description: _connectionDescription,
                  bridgeUrl: _bridgeUrl,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _cancelConnection,
                  child: const Text('Back to Bridge Setup'),
                ),
              ],
              if (_error != null && !_verifying) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _modeDescription(String mode) {
    switch (mode) {
      case 'local_only':
        return 'Loopback only';
      case 'private_network':
        return 'Private network';
      case 'secure_remote':
        return 'Secure tunnel';
      case 'direct_public':
        return 'Direct public remote';
      case 'misconfigured':
        return 'Insecure configuration';
      default:
        return 'Bridge connection';
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 56, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF9CDCFE)),
          ),
        ],
      ),
    );
  }
}

class _ConnectionModeCard extends StatelessWidget {
  const _ConnectionModeCard({
    required this.mode,
    required this.description,
    required this.bridgeUrl,
  });

  final String mode;
  final String description;
  final String bridgeUrl;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      'local_only' => '🏠',
      'private_network' => '📶',
      'secure_remote' => '🛡️',
      'direct_public' => '⚠️',
      'misconfigured' => '❌',
      _ => '🔌',
    };
    final label = switch (mode) {
      'local_only' => 'Local-only',
      'private_network' => 'Private Network',
      'secure_remote' => 'Secure Remote',
      'direct_public' => 'Direct Public Remote',
      'misconfigured' => 'Misconfigured',
      _ => 'Bridge Connection',
    };

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon  $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bridgeUrl,
            style: const TextStyle(color: Color(0xFF9CDCFE)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.passed});

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel_outlined,
            color: passed ? const Color(0xFF4CAF50) : Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBullet extends StatelessWidget {
  const _RiskBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
