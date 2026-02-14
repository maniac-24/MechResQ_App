// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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

              

              const SizedBox(height: 10),

              

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

              

              const SizedBox(height: 12),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
