import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _kBoxName = 'preferences';
const String _kThemeMode = 'theme_mode';
const String _kDefaultAgentId = 'default_agent_id';
const String _kNotificationsEnabled = 'notifications_enabled';
const String _kBridgeUrl = 'bridge_url';
const String _kHighContrast = 'high_contrast';

/// App preferences backed by a Hive key-value box.
/// No HiveType annotations are needed — this class uses a dynamic string-keyed box.
class AppPreferences {
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_kBoxName);
  }

  ThemeMode getThemeMode() {
    final value = _box.get(_kThemeMode, defaultValue: 'system') as String;
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _box.put(_kThemeMode, value);
  }

  String? getDefaultAgentId() {
    return _box.get(_kDefaultAgentId) as String?;
  }

  Future<void> setDefaultAgentId(String? id) async {
    if (id == null) {
      await _box.delete(_kDefaultAgentId);
    } else {
      await _box.put(_kDefaultAgentId, id);
    }
  }

  bool getNotificationsEnabled() {
    return _box.get(_kNotificationsEnabled, defaultValue: true) as bool;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put(_kNotificationsEnabled, enabled);
  }

  String? getBridgeUrl() {
    return _box.get(_kBridgeUrl) as String?;
  }

  Future<void> setBridgeUrl(String? url) async {
    if (url == null) {
      await _box.delete(_kBridgeUrl);
    } else {
      await _box.put(_kBridgeUrl, url);
    }
  }

  bool getHighContrast() {
    return _box.get(_kHighContrast, defaultValue: false) as bool;
  }

  Future<void> setHighContrast(bool val) async {
    await _box.put(_kHighContrast, val);
  }
}
