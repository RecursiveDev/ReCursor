import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/agent_models.dart';
import '../../domain/providers/agent_provider.dart';

const _uuid = Uuid();

/// Create or edit an [AgentConfig].
///
/// Pass an existing [AgentConfig] via route `extra` for edit mode.
class AgentConfigScreen extends ConsumerStatefulWidget {
  final AgentConfig? existingAgent;

  const AgentConfigScreen({super.key, this.existingAgent});

  @override
  ConsumerState<AgentConfigScreen> createState() => _AgentConfigScreenState();
}

class _AgentConfigScreenState extends ConsumerState<AgentConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bridgeUrlController;
  late final TextEditingController _tokenController;
  late AgentType _agentType;
  bool _obscureToken = true;
  bool _isTesting = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingAgent != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existingAgent;
    _nameController = TextEditingController(text: a?.displayName ?? '');
    _bridgeUrlController = TextEditingController(text: a?.bridgeUrl ?? '');
    _tokenController = TextEditingController(text: a?.authToken ?? '');
    _agentType = a?.type ?? AgentType.claudeCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bridgeUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final agent = AgentConfig(
      id: widget.existingAgent?.id ?? _uuid.v4(),
      displayName: _nameController.text.trim(),
      type: _agentType,
      bridgeUrl: _bridgeUrlController.text.trim(),
      authToken: _tokenController.text.trim(),
      status: AgentConnectionStatus.disconnected,
      createdAt: widget.existingAgent?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditMode) {
      await ref.read(agentsProvider.notifier).updateAgent(agent);
    } else {
      await ref.read(agentsProvider.notifier).add(agent);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  Future<void> _delete() async {
    final id = widget.existingAgent!.id;
    await ref.read(agentsProvider.notifier).delete(id);
    if (mounted) context.pop();
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    final ok = await ref.read(agentsProvider.notifier).testConnection(
          _bridgeUrlController.text.trim(),
          _tokenController.text.trim(),
        );
    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Connection successful' : 'Connection failed'),
          backgroundColor:
              ok ? const Color(0xFF4CAF50) : const Color(0xFFF44747),
        ),
      );
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (result != null) {
      _bridgeUrlController.text = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Agent' : 'Add Agent'),
        actions: [
          if (_isEditMode)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') _delete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Display name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Agent type dropdown
            DropdownButtonFormField<AgentType>(
              value: _agentType,
              decoration: const InputDecoration(labelText: 'Agent Type'),
              dropdownColor: const Color(0xFF252526),
              items: AgentType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _agentType = v!),
            ),
            const SizedBox(height: 16),

            // Bridge URL
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _bridgeUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Bridge URL',
                      hintText: 'wss://host:3000',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Scan QR',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanQr,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Auth token (obscured)
            TextFormField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: 'Auth Token',
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureToken = !_obscureToken),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Test connection button
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering, size: 18),
              label: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QR scanner page
// ---------------------------------------------------------------------------

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final barcode = capture.barcodes.firstOrNull;
          final value = barcode?.rawValue;
          if (value != null && value.isNotEmpty) {
            _scanned = true;
            Navigator.of(context).pop(value);
          }
        },
      ),
    );
  }
}
