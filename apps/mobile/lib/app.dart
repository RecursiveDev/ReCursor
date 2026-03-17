import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/router.dart';
import 'core/config/theme.dart';
import 'core/providers/theme_provider.dart';

class ReCursorApp extends ConsumerWidget {
  const ReCursorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final highContrast = ref.watch(highContrastProvider);

    final effectiveDarkTheme =
        highContrast ? AppTheme.highContrastTheme : AppTheme.darkTheme;

    return MaterialApp.router(
      title: 'ReCursor',
      theme: highContrast ? AppTheme.highContrastTheme : AppTheme.lightTheme,
      darkTheme: effectiveDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
