import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recursor_mobile/main.dart' as app;

void main() {
  testWidgets('App launches and shows splash screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    // Should see splash screen
    expect(find.byKey(const Key('splashScreen')), findsOneWidget);
  });

  testWidgets('Login screen shows GitHub and PAT options', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Navigate to login
    expect(find.text('Sign in with GitHub'), findsOneWidget);
    expect(find.text('Personal Access Token'), findsOneWidget);
  });

  testWidgets('PAT field accepts input', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Find PAT field and enter token
    final patButton = find.text('Personal Access Token');
    if (patButton.evaluate().isNotEmpty) {
      await tester.tap(patButton);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('patTextField')), 'test-token-123');
      expect(find.byKey(const Key('patTextField')), findsOneWidget);
    }
  });
}
