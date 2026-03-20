import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connection_state.dart';
import '../../../../core/providers/bridge_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/token_storage_provider.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../widgets/setting_tile.dart';

final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final _notificationsEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(_themeModeProvider);
    final notificationsEnabled = ref.watch(_notificationsEnabledProvider);
    final highContrast = ref.watch(highContrastProvider);
    final bridgeStatus = ref.watch(bridgeProvider);
    final preferences = ref.watch(appPreferencesProvider);
    final bridgeUrl = preferences.getBridgeUrl();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(label: 'APPEARANCE'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ],
              selected: {themeMode},
              onSelectionChanged: (selection) {
                ref.read(_themeModeProvider.notifier).state = selection.first;
              },
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('High contrast'),
            subtitle: const Text('Increases contrast for better visibility'),
            value: highContrast,
            onChanged: (value) {
              ref.read(highContrastProvider.notifier).setHighContrast(value);
            },
          ),
          const Divider(height: 1),
          const _SectionHeader(label: 'NOTIFICATIONS'),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Enable notifications'),
            value: notificationsEnabled,
            onChanged: (value) {
              ref.read(_notificationsEnabledProvider.notifier).state = value;
            },
          ),
          const Divider(height: 1),
          const _SectionHeader(label: 'BRIDGE'),
          SettingTile(
            leading: const Icon(Icons.link, size: 20),
            title: const Text('Saved bridge'),
            subtitle: Text(
              bridgeUrl == null || bridgeUrl.isEmpty
                  ? 'No bridge paired yet'
                  : bridgeUrl,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 12,
              ),
            ),
          ),
          SettingTile(
            leading: const Icon(Icons.route, size: 20),
            title: const Text('Run bridge setup'),
            subtitle: const Text(
              'Update the saved bridge URL or pairing token',
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            onTap: () => context.go('/bridge-setup'),
          ),
          SettingTile(
            leading: Icon(
              bridgeStatus == ConnectionStatus.connected
                  ? Icons.link_off
                  : Icons.link,
              size: 20,
              color: bridgeStatus == ConnectionStatus.connected
                  ? const Color(0xFFF44747)
                  : const Color(0xFF9E9E9E),
            ),
            title: Text(
              bridgeStatus == ConnectionStatus.connected
                  ? 'Disconnect'
                  : 'Bridge offline',
              style: TextStyle(
                color: bridgeStatus == ConnectionStatus.connected
                    ? const Color(0xFFF44747)
                    : const Color(0xFF9E9E9E),
              ),
            ),
            subtitle: Text(
              switch (bridgeStatus) {
                ConnectionStatus.connected => 'Connected to the paired bridge',
                ConnectionStatus.connecting => 'Connecting…',
                ConnectionStatus.reconnecting => 'Reconnecting…',
                ConnectionStatus.error => 'Last bridge connection failed',
                ConnectionStatus.disconnected => 'No active bridge connection',
              },
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            onTap: bridgeStatus == ConnectionStatus.connected
                ? () {
                    ref.read(bridgeProvider.notifier).disconnect();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Disconnected from bridge')),
                    );
                  }
                : null,
          ),
          SettingTile(
            leading: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Color(0xFFF44747),
            ),
            title: const Text(
              'Forget saved pairing',
              style: TextStyle(color: Color(0xFFF44747)),
            ),
            subtitle: const Text(
              'Clears the saved bridge URL and pairing token',
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            showDivider: false,
            onTap: () {
              unawaited(_forgetSavedPairing(context, ref));
            },
          ),
          const Divider(height: 1),
          const _SectionHeader(label: 'ABOUT'),
          const SettingTile(
            leading: Icon(Icons.info_outline, size: 20),
            title: Text('Version'),
            trailing: Text(
              '0.1.0',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9E9E9E),
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          SettingTile(
            leading: const Icon(Icons.description_outlined, size: 20),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'ReCursor',
              applicationVersion: '0.1.0',
            ),
          ),
          SettingTile(
            leading: const Icon(Icons.open_in_new, size: 20),
            title: const Text('GitHub'),
            showDivider: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('https://github.com/RecursiveDev/ReCursor'),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _forgetSavedPairing(BuildContext context, WidgetRef ref) async {
    ref.read(bridgeProvider.notifier).disconnect();
    await ref.read(appPreferencesProvider).setBridgeUrl(null);
    await ref.read(tokenStorageProvider).deleteToken(kBridgeToken);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared saved bridge pairing')),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}
