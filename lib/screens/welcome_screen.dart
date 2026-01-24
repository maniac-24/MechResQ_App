// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // HERO ICON WITH PNG LOGO
  Widget _heroIcon() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/mechresq_logo.png',   // <--- PNG LOGO HERE
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
          child: Column(
            children: [
              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: yellow,
                  size: 28,
                ),
              ),

              SizedBox(height: 18),

              Text(
                'MechResQ - Emergency Roadside Assistance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 10),

              Text(
                'Your trusted partner for roadside assistance and vehicle repairs.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 28),

              // PNG LOGO HERO ICON
              _heroIcon(),

              Spacer(),

              PrimaryButton(
                text: 'Login',
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),

              SizedBox(height: 12),

              SecondaryButton(
                text: 'Create User Account',
                onPressed: () =>
                    Navigator.pushNamed(context, '/register_user'),
              ),

              SizedBox(height: 12),

              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/register_mechanic'),
                child: Text(
                  'Are you a mechanic? Register here',
                  style: TextStyle(color: yellow),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
