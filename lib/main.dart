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
        scaffoldBackgroundColor: Color(0xFFF5F6F8),
        primarySwatch: Colors.indigo,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: EdgeInsets.all(16),
          ),
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
