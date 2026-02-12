// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
          child: Column(
            children: [
              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.primary,
                  size: 28,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                l10n.welcomeTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                l10n.welcomeSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/mechresq_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Spacer(),

              PrimaryButton(
                text: l10n.loginButton,
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),

              const SizedBox(height: 12),

              SecondaryButton(
                text: l10n.createUserAccountButton,
                onPressed: () =>
                    Navigator.pushNamed(context, '/register_user'),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/register_mechanic'),
                child: Text(
                  l10n.mechanicRegisterPrompt,
                  style: TextStyle(color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
