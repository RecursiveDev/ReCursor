import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/network/bridge_connection_validator.dart';
import '../../../../core/providers/bridge_provider.dart';
import '../../../../core/providers/preferences_provider.dart';
import '../../../../core/providers/token_storage_provider.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../domain/bridge_startup_controller.dart';

class BridgeSetupScreen extends ConsumerStatefulWidget {
  const BridgeSetupScreen({super.key});

  @override
  ConsumerState<BridgeSetupScreen> createState() => _BridgeSetupScreenState();
}

class _BridgeSetupScreenState extends ConsumerState<BridgeSetupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _connecting = false;
  String? _error;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    unawaited(_loadSavedBridgeConfig());
  }

  Future<void> _loadSavedBridgeConfig() async {
    final preferences = ref.read(appPreferencesProvider);
    final storage = ref.read(tokenStorageProvider);
    final savedUrl = preferences.getBridgeUrl();
    final savedToken = await storage.getToken(kBridgeToken);
    final startupError = ref.read(bridgeStartupErrorProvider);

    if (!mounted) {
      return;
    }

    setState(() {
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _urlController.text = savedUrl;
      }
      if (savedToken != null && savedToken.isNotEmpty) {
        _tokenController.text = savedToken;
      }
      if (startupError != null && startupError.isNotEmpty) {
        _error = startupError;
      }
    });

    ref.read(bridgeStartupErrorProvider.notifier).state = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_scanned) {
      return;
    }

    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) {
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      _setError('QR code did not contain a valid bridge pairing URI.');
      return;
    }

    final url = uri.queryParameters['url'] ?? '';
    final token = uri.queryParameters['token'] ?? '';
    final validation = BridgeConnectionValidator.validate(
      url: url,
      token: token,
    );

    if (!validation.isValid) {
      _setError(validation.errorMessage!);
      return;
    }

    setState(() {
      _scanned = true;
      _error = null;
      _urlController.text = url;
      _tokenController.text = token;
    });
    _tabController.animateTo(1);
  }

  void _setError(String message) {
    setState(() {
      _error = message;
    });
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    final validation = BridgeConnectionValidator.validate(
      url: url,
      token: token,
    );

    if (!validation.isValid) {
      _setError(validation.errorMessage!);
      return;
    }

    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      await ref.read(bridgeProvider.notifier).connect(url, token);
      await ref.read(appPreferencesProvider).setBridgeUrl(url);
      await ref.read(tokenStorageProvider).saveToken(kBridgeToken, token);
      ref.read(bridgeStartupErrorProvider.notifier).state = null;
      if (mounted) {
        context.go('/home/chat');
      }
    } catch (error) {
      _setError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  Widget _buildTabBody() {
    return AnimatedBuilder(
      animation: _tabController.animation ?? _tabController,
      builder: (context, _) {
        final currentIndex = _tabController.index;
        if (currentIndex == 0) {
          return _QrTab(onDetect: _onQrDetect);
        }
        return _ManualTab(
          urlController: _urlController,
          tokenController: _tokenController,
          connecting: _connecting,
          error: _error,
          onConnect: _connect,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('bridgeSetupScreen'),
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        title: const Text('Bridge Setup'),
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
      body: _buildTabBody(),
    );
  }
}

class _QrTab extends StatelessWidget {
  const _QrTab({required this.onDetect});

  final void Function(BarcodeCapture) onDetect;

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
            'Scan a QR code that contains your private wss:// bridge URL and '
            'bridge pairing token.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CDCFE)),
          ),
        ),
      ],
    );
  }
}

class _ManualTab extends StatelessWidget {
  const _ManualTab({
    required this.urlController,
    required this.tokenController,
    required this.connecting,
    required this.error,
    required this.onConnect,
  });

  final TextEditingController urlController;
  final TextEditingController tokenController;
  final bool connecting;
  final String? error;
  final VoidCallback onConnect;

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
          const Text(
            'Start by pairing with your local bridge. No account sign-in is '
            'required.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the bridge\'s private Tailscale/WireGuard address. Public '
            'internet bridge endpoints are outside the docs contract.',
            style: TextStyle(color: Color(0xFF9CDCFE)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            style: const TextStyle(color: Colors.white),
            decoration: inputDecoration.copyWith(
              labelText: 'Bridge URL (wss://...)',
              hintText: 'wss://your-bridge.tailnet.ts.net:3000',
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: tokenController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: inputDecoration.copyWith(
              labelText: 'Bridge Pairing Token',
              helperText: 'Stored securely on-device after a successful pair.',
              helperStyle: const TextStyle(color: Colors.grey),
            ),
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
