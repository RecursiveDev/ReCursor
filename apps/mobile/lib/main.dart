import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/providers/theme_provider.dart';
import 'core/storage/preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final prefs = AppPreferences();
  await prefs.init();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    SentryService.captureException(details.exception, stackTrace: details.stack);
  };

  await SentryService.init(() => runApp(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const ReCursorApp(),
        ),
      ));
}
