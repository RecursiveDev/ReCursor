import 'package:sentry_flutter/sentry_flutter.dart';

class SentryService {
  static const String _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static bool get isConfigured => _dsn.isNotEmpty;

  // Initialize Sentry — call before runApp
  static Future<void> init(AppRunner appRunner) async {
    if (!isConfigured) {
      appRunner();
      return;
    }
    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = const String.fromEnvironment('APP_ENV',
            defaultValue: 'development');
        options.tracesSampleRate = 0.2;
        options.profilesSampleRate = 0.1;
        options.attachScreenshot = true;
        options.enableAutoPerformanceTracing = true;
      },
      appRunner: appRunner,
    );
  }

  // Capture an exception manually
  static Future<void> captureException(Object exception,
      {StackTrace? stackTrace}) async {
    if (!isConfigured) return;
    await Sentry.captureException(exception, stackTrace: stackTrace);
  }

  // Add breadcrumb
  static void addBreadcrumb(String message,
      {String? category, Map<String, dynamic>? data}) {
    if (!isConfigured) return;
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      data: data,
    ));
  }

  // Set user context
  static void setUser(String? id, String? username) {
    if (!isConfigured) return;
    Sentry.configureScope((scope) {
      scope.setUser(id != null ? SentryUser(id: id, username: username) : null);
    });
  }
}

typedef AppRunner = void Function();
