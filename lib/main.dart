import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:flutter/foundation.dart";

import "firebase_options.dart";
import "pages/login_page.dart";
import "pages/reports_page.dart";

// Use emulators only when requested with --dart-define=USE_EMULATORS=true.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String startupError = "";
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (const bool.fromEnvironment("USE_EMULATORS")) {
      const String host = String.fromEnvironment(
        "EMULATOR_HOST",
        defaultValue: "127.0.0.1",
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9199);
      // Keep local emulator sessions out of persistent browser Auth storage.
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.NONE);
      }
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8188);
    }
  } catch (e) {
    debugPrint("QuickFix startup: $e");
    startupError =
        "QuickFix could not connect. Check your connection and restart the app.";
  }
  runApp(MyApp(startupError: startupError));
}

class MyApp extends StatelessWidget {
  final String startupError;
  const MyApp({super.key, this.startupError = ""});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "QuickFix",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Campus Service look: navy (0xFF1F3A5F) and gold (0xFFF2B134) on a pale page.
        scaffoldBackgroundColor: Color(0xFFF3F5F9),
        // Dropdown menus use this color, so they are white instead of tinted.
        canvasColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1F3A5F),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF1F3A5F), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1F3A5F),
            foregroundColor: Colors.white,
            padding: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // White surfaces and navy buttons, so no default purple tint shows.
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFFDFE5EE)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Color(0xFF1F3A5F)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF1F3A5F),
            side: BorderSide(color: Color(0xFF1F3A5F)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(backgroundColor: Colors.white),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFF1F3A5F),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Color(0xFF1F3A5F),
        ),
      ),
      home: startupError.isNotEmpty
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(startupError),
                ),
              ),
            )
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.data == null) {
                  return LoginPage();
                }
                return ReportsPage(key: ValueKey(snapshot.data!.uid));
              },
            ),
    );
  }
}
