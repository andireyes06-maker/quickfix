import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:quickfix/pages/login_page.dart";
import "package:quickfix/pages/report_form_page.dart";

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
