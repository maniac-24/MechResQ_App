// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter a valid email')));
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.forgotPassword(email: email);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Reset Link Sent'),
          content: Text(
            'A password reset link (simulated) was sent to $email.\n\n'
            'In a real app, this will trigger an email service.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password')),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address.\n'
              'We will send you a reset link (simulated).',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loading ? null : _sendReset,
              child: _loading
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: Center(child: Text('Send Reset Link')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
