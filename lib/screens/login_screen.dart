import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/google_auth_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

/// User role constants for type-safe role checking
/// (Should match UserRoles from home_router.dart)
class UserRoles {
  UserRoles._(); // Private constructor
  
  static const String mechanic = 'mechanic';
  static const String user = 'user';
}

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
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        "Login failed: ${e.toString()}",
      );
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
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        "Google login failed: ${e.toString()}",
      );
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

      // Lifecycle-safe navigation using post-frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Type-safe role handling with fallback
        switch (role) {
          case UserRoles.mechanic:
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/mechanic_root",
              (_) => false,
            );
            break;

          case UserRoles.user:
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/home",
              (_) => false,
            );
            break;

          default:
            // Unknown/corrupted role → redirect to appropriate registration
            if (_loginType == LoginType.mechanic) {
              Navigator.pushReplacementNamed(context, "/register_mechanic");
            } else {
              Navigator.pushReplacementNamed(context, "/register_user");
            }
        }
      });
    } catch (e) {
      // profile not found → go to register page
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (_loginType == LoginType.mechanic) {
          Navigator.pushReplacementNamed(context, "/register_mechanic");
        } else {
          Navigator.pushReplacementNamed(context, "/register_user");
        }
      });
    }
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
    final scheme = Theme.of(context).colorScheme;

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
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
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
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
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
                        activeColor: scheme.primary,
                        onChanged: (v) => setState(() => _loginType = v!),
                      ),
                      Text(
                        "User",
                        style: TextStyle(color: scheme.onSurface),
                      ),
                      const SizedBox(width: 24),
                      Radio<LoginType>(
                        value: LoginType.mechanic,
                        groupValue: _loginType,
                        activeColor: scheme.primary,
                        onChanged: (v) => setState(() => _loginType = v!),
                      ),
                      Text(
                        "Mechanic",
                        style: TextStyle(color: scheme.onSurface),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ✅ LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                      ),
                      onPressed: _loading ? null : _loginWithEmail,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _loading
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
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
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      TextButton(
                        onPressed: _goToRegister,
                        child: Text(
                          "Register",
                          style: TextStyle(
                            color: scheme.primary,
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