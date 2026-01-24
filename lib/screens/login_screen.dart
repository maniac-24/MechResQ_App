// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/google_auth_service.dart';
import '../services/auth_service.dart';

enum LoginType { user, mechanic }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  LoginType _loginType = LoginType.user;

  final GoogleAuthService _googleAuth = GoogleAuthService();
  final AuthService _backendAuth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ EMAIL/PASSWORD LOGIN (FIREBASE)
  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _afterLogin();
    } catch (e) {
      _showMsg("Login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ GOOGLE LOGIN
  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);

    try {
      await _googleAuth.signInWithGoogle();
      await _afterLogin();
    } catch (e) {
      _showMsg("Google login failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ AFTER LOGIN → CHECK PROFILE IN FIRESTORE
  Future<void> _afterLogin() async {
    try {
      final profile = await _backendAuth.getMyProfile();

      if (profile == null) {
        throw Exception("Profile not found");
      }

      final role = profile["role"]?.toString();

      if (!mounted) return;

      if (role == "mechanic") {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/mechanic_root",
          (_) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/home",
          (_) => false,
        );
      }
    } catch (e) {
      // profile not found → go to register page
      if (!mounted) return;

      if (_loginType == LoginType.mechanic) {
        Navigator.pushReplacementNamed(context, "/register_mechanic");
      } else {
        Navigator.pushReplacementNamed(context, "/register_user");
      }
    }
  }

  void _showMsg(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToRegister() {
    if (_loginType == LoginType.mechanic) {
      Navigator.pushNamed(context, "/register_mechanic");
    } else {
      Navigator.pushNamed(context, "/register_user");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login"), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // ✅ EMAIL
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = (v ?? "").trim();
                      if (val.isEmpty) return "Enter email";
                      if (!val.contains("@")) return "Enter valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ✅ PASSWORD
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (v) {
                      final val = (v ?? "").trim();
                      if (val.isEmpty) return "Enter password";
                      if (val.length < 6) return "Min 6 characters";
                      return null;
                    },
                  ),

                  // ✅ FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/forgot_password"),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ ROLE RADIO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<LoginType>(
                        value: LoginType.user,
                        groupValue: _loginType,
                        onChanged: (v) => setState(() => _loginType = v!),
                      ),
                      const Text("User"),
                      const SizedBox(width: 24),
                      Radio<LoginType>(
                        value: LoginType.mechanic,
                        groupValue: _loginType,
                        onChanged: (v) => setState(() => _loginType = v!),
                      ),
                      const Text("Mechanic"),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ✅ LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loginWithEmail,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Login"),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ✅ GOOGLE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _loginWithGoogle,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text("Sign in with Google"),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ REGISTER LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: _goToRegister,
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
