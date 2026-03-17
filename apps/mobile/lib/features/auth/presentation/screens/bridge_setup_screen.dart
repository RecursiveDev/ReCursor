import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/providers/bridge_provider.dart';

class BridgeSetupScreen extends ConsumerStatefulWidget {
  const BridgeSetupScreen({super.key});

  @override
  ConsumerState<BridgeSetupScreen> createState() => _BridgeSetupScreenState();
}

class _BridgeSetupScreenState extends ConsumerState<BridgeSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _connecting = false;
  String? _error;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    // Expected format: recursor://connect?url=wss://...&token=...
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final url = uri.queryParameters['url'] ?? '';
      final token = uri.queryParameters['token'] ?? '';
      if (url.isNotEmpty) {
        setState(() {
          _scanned = true;
          _urlController.text = url;
          _tokenController.text = token;
        });
        _tabController.animateTo(1);
      }
    }
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Bridge URL is required');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    try {
      await ref.read(bridgeProvider.notifier).connect(url, token);
      if (mounted) context.go('/home/chat');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: const Text('Connect Bridge'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF569CD6),
          labelColor: const Color(0xFF569CD6),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR Scanner'),
            Tab(icon: Icon(Icons.edit), text: 'Manual Entry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _QrTab(onDetect: _onQrDetect),
          _ManualTab(
            urlController: _urlController,
            tokenController: _tokenController,
            connecting: _connecting,
            error: _error,
            onConnect: _connect,
          ),
        ],
      ),
    );
  }
}

class _QrTab extends StatelessWidget {
  final void Function(BarcodeCapture) onDetect;
  const _QrTab({required this.onDetect});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(onDetect: onDetect),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Point the camera at the QR code shown in your bridge server',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CDCFE)),
          ),
        ),
      ],
    );
  }
}

class _ManualTab extends StatelessWidget {
  final TextEditingController urlController;
  final TextEditingController tokenController;
  final bool connecting;
  final String? error;
  final VoidCallback onConnect;

  const _ManualTab({
    required this.urlController,
    required this.tokenController,
    required this.connecting,
    required this.error,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    const inputDecoration = InputDecoration(
      filled: true,
      fillColor: Color(0xFF252526),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide.none,
      ),
      labelStyle: TextStyle(color: Color(0xFF9CDCFE)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: urlController,
            style: const TextStyle(color: Colors.white),
            decoration: inputDecoration.copyWith(
              labelText: 'Bridge URL (wss://...)',
              hintText: 'wss://192.168.1.100:8080',
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: tokenController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration:
                inputDecoration.copyWith(labelText: 'Auth Token (optional)'),
          ),
          const SizedBox(height: 24),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          FilledButton(
            onPressed: connecting ? null : onConnect,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF569CD6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: connecting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Connect', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
