import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:quickfix/pages/login_page.dart";
import "package:quickfix/pages/report_form_page.dart";
import "package:quickfix/pages/reports_page.dart";

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

  testWidgets("Registration shows a mismatch error", (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage()));
    await tester.tap(find.text("New to QuickFix? Create an account"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, "Full name"),
      "Maria Santos",
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, "Email"),
      "maria@example.com",
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, "Password"),
      "secret1",
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, "Confirm password"),
      "secret2",
    );
    await tester.ensureVisible(find.text("Create account"));
    await tester.tap(find.text("Create account"));
    await tester.pumpAndSettle();
    expect(find.text("Passwords do not match"), findsOneWidget);
  });

  testWidgets("Login has no overflow at 320 wide and 2x text", (tester) async {
    tester.view.physicalSize = Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2.0)),
            child: child!,
          );
        },
        home: LoginPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text("New to QuickFix? Create an account"));
    await tester.tap(find.text("New to QuickFix? Create an account"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test("firstNameOf gives a friendly first name", () {
    expect(firstNameOf("Maria Santos"), "Maria");
    expect(firstNameOf("  Juan  "), "Juan");
    expect(firstNameOf(""), "there");
    expect(firstNameOf(null), "there");
  });

  test("openReportsLine counts open reports", () {
    expect(openReportsLine(0), "No open reports right now.");
    expect(openReportsLine(1), "1 open report. Thanks for helping our campus.");
    expect(openReportsLine(3), "3 open reports. Thanks for helping our campus.");
  });

  test("stepsLine says how many steps are done", () {
    expect(stepsLine(0), "0 of 3 steps done.");
    expect(stepsLine(1), "1 of 3 steps done.");
    expect(stepsLine(2), "2 of 3 steps done.");
    expect(stepsLine(3), "All set. Ready to submit.");
  });

  test("photoTypeFor accepts only jpeg, png, webp", () {
    expect(photoTypeFor("image/png", "a.bin"), "image/png");
    expect(photoTypeFor("image/jpg", "a"), "image/jpeg");
    expect(photoTypeFor("", "PHOTO.JPG"), "image/jpeg");
    expect(photoTypeFor("", "x.jpeg"), "image/jpeg");
    expect(photoTypeFor("", "x.webp"), "image/webp");
    expect(photoTypeFor("", "x.gif"), "");
    expect(photoTypeFor("", "noextension"), "");
    expect(photoTypeFor("image/heic", "a.heic"), "");
    expect(photoTypeFor("image/gif", "x.jpg"), "");
  });
}
