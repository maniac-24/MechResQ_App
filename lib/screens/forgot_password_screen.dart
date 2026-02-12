// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final AuthService _auth = AuthService();
  bool _loading = false;

  void _sendReset() async {
    final email = _email.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      SnackBarHelper.showError(
        context,
        'Please enter a valid email address',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.forgotPassword(email: email);

      if (!mounted) return;

      _showSuccessDialog(email);
    } catch (e) {
      if (!mounted) return;

      SnackBarHelper.showError(
        context,
        e.toString(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(String email) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          'Reset Link Sent',
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          'A password reset link has been sent to:\n\n$email\n\n'
          'Please check your inbox and follow the instructions.',
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address.\n'
              'We will send you a password reset link.',
              style: TextStyle(
                fontSize: 15,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendReset,
                child: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
