import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();
  bool register = false;
  bool busy = false;
  bool hidePassword = true;
  String error = "";

  // REGISTER / LOGIN
  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = "";
    });
    try {
      if (register) {
        final result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text,
            );
        // The account exists now, so a failed name save should not look like a failed sign up.
        try {
          await result.user!.updateDisplayName(nameController.text.trim());
        } catch (e) {
          /* The name can be set again later. */
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (e.code == "email-already-in-use") {
          error = "This email already has an account. Please sign in.";
        } else if (e.code == "invalid-email") {
          error = "Please enter a valid email address.";
        } else if (e.code == "network-request-failed") {
          error = "Check your internet connection and try again.";
        } else if (e.code == "too-many-requests") {
          error = "Too many attempts. Please try again later.";
        } else {
          error = register
              ? "Could not create the account. Please try again."
              : "Incorrect email or password.";
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        error = "Something went wrong. Please try again.";
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navy brand area at the top of the page.
            Container(
              color: Color(0xFF1F3A5F),
              padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Color(0xFFF2B134),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.handyman_outlined,
                        size: 36,
                        color: Color(0xFF1F3A5F),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "QuickFix",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Campus maintenance reports",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFFDFE5EE)),
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            register
                                ? "Create your student account"
                                : "Welcome back",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F3A5F),
                            ),
                          ),
                          SizedBox(height: 20),
                          if (register) ...[
                            TextFormField(
                              controller: nameController,
                              enabled: !busy,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: "Full name",
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter your full name";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: emailController,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: [AutofillHints.email],
                            decoration: InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter your email";
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            enabled: !busy,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: hidePassword
                                    ? "Show password"
                                    : "Hide password",
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your password";
                              }
                              if (register && value.length < 6) {
                                return "Use at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          if (register) ...[
                            SizedBox(height: 16),
                            TextFormField(
                              controller: confirmController,
                              enabled: !busy,
                              obscureText: hidePassword,
                              decoration: InputDecoration(
                                labelText: "Confirm password",
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value != passwordController.text) {
                                  return "Passwords do not match";
                                }
                                return null;
                              },
                            ),
                          ],
                          if (error.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                error,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: busy ? null : submit,
                            child: Text(
                              busy
                                  ? "Please wait..."
                                  : register
                                  ? "Create account"
                                  : "Sign in",
                            ),
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    setState(() {
                                      register = !register;
                                      error = "";
                                    });
                                    formKey.currentState!.reset();
                                  },
                            child: Text(
                              register
                                  ? "Already registered? Sign in"
                                  : "New to QuickFix? Create an account",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
