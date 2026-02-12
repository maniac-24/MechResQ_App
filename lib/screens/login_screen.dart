import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/google_auth_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import '../l10n/app_localizations.dart';

class UserRoles {
  UserRoles._();
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

  Future<void> _loginWithEmail() async {
    final l10n = AppLocalizations.of(context)!;

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
        "${l10n.loginFailed}: ${e.toString()}",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _loading = true);

    try {
      await _googleAuth.signInWithGoogle();
      await _afterLogin();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        "${l10n.googleLoginFailed}: ${e.toString()}",
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _afterLogin() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final profile = await _backendAuth.getMyProfile();

      if (profile == null) {
        throw Exception(l10n.profileNotFound);
      }

      final role = profile["role"]?.toString();

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

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
            _goToRegister();
        }
      });
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goToRegister();
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginTitle),
        centerTitle: true,
      ),
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
                    l10n.welcomeBack,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = (v ?? "").trim();
                      if (val.isEmpty) return l10n.enterEmail;
                      if (!val.contains("@")) return l10n.enterValidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
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
                      if (val.isEmpty) return l10n.enterPassword;
                      if (val.length < 6) {
                        return l10n.minCharacters(6);
                      }
                      return null;
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/forgot_password"),
                      child: Text(l10n.forgotPassword),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<LoginType>(
                        value: LoginType.user,
                        groupValue: _loginType,
                        activeColor: scheme.primary,
                        onChanged: (v) =>
                            setState(() => _loginType = v!),
                      ),
                      Text(l10n.userRole),

                      const SizedBox(width: 24),

                      Radio<LoginType>(
                        value: LoginType.mechanic,
                        groupValue: _loginType,
                        activeColor: scheme.primary,
                        onChanged: (v) =>
                            setState(() => _loginType = v!),
                      ),
                      Text(l10n.mechanicRole),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loginWithEmail,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        child: _loading
                            ? const CircularProgressIndicator()
                            : Text(l10n.loginTitle),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          _loading ? null : _loginWithGoogle,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        child: Text(l10n.signInWithGoogle),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(l10n.noAccount),
                      TextButton(
                        onPressed: _goToRegister,
                        child: Text(
                          l10n.register,
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
