import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/websocket_provider.dart';
import '../../../../core/storage/preferences.dart';
import '../widgets/setting_tile.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _preferencesProvider = Provider<AppPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope overrides');
});

final _themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final _notificationsEnabledProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Settings screen
// ---------------------------------------------------------------------------

/// Main settings screen grouped into Appearance, Notifications, Bridge,
/// Account, and About sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(_themeModeProvider);
    final notificationsEnabled = ref.watch(_notificationsEnabledProvider);
    final highContrast = ref.watch(highContrastProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(label: 'APPEARANCE'),
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
                ref.read(_themeModeProvider.notifier).state =
                    selection.first;
              },
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('High contrast'),
            subtitle: const Text('Increases contrast for better visibility'),
            value: highContrast,
            onChanged: (v) {
              ref.read(highContrastProvider.notifier).setHighContrast(v);
            },
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'NOTIFICATIONS'),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Enable notifications'),
            value: notificationsEnabled,
            onChanged: (v) {
              ref.read(_notificationsEnabledProvider.notifier).state = v;
            },
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'BRIDGE'),
          SettingTile(
            leading: const Icon(Icons.link, size: 20),
            title: const Text('Bridge URL'),
            subtitle: const Text(
              'Not connected',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ),
          SettingTile(
            leading: const Icon(Icons.link_off, size: 20,
                color: Color(0xFFF44747)),
            title: const Text(
              'Disconnect',
              style: TextStyle(color: Color(0xFFF44747)),
            ),
            showDivider: false,
            onTap: () {
              final service = ref.read(webSocketServiceProvider);
              service.disconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disconnected from bridge')),
              );
            },
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'ACCOUNT'),
          SettingTile(
            leading: authState.avatarUrl != null
                ? CircleAvatar(
                    backgroundImage:
                        NetworkImage(authState.avatarUrl!),
                    radius: 16,
                  )
                : const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 18),
                  ),
            title: Text(authState.username ?? 'Unknown user'),
            subtitle: const Text(
              'GitHub',
              style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
            ),
          ),
          SettingTile(
            leading: const Icon(Icons.logout, size: 20,
                color: Color(0xFFF44747)),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFF44747)),
            ),
            showDivider: false,
            onTap: () {
              ref.read(authStateProvider.notifier).signOut();
            },
          ),
          const Divider(height: 1),

          _SectionHeader(label: 'ABOUT'),
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
              // Link would be opened via url_launcher in a real implementation.
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
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

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
