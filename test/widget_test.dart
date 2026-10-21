import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:quickfix/pages/login_page.dart";

void main() {
  testWidgets("Registration validates before contacting Firebase", (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage()));
    await tester.tap(find.text("New to QuickFix? Create an account"));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Create account"));
    await tester.tap(find.text("Create account"));
    await tester.pumpAndSettle();
    expect(find.text("Please enter your full name"), findsOneWidget);
    expect(find.text("Please enter your email"), findsOneWidget);
    expect(find.text("Please enter your password"), findsOneWidget);
  });
}
