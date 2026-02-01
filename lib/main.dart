import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'theme.dart';
import 'services/auth_service.dart';

// SCREENS
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_user_screen.dart';
import 'screens/register_mechanic_screen.dart';
import 'screens/shop_location_picker_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_requests_screen.dart';
import 'screens/create_request_screen.dart';
import 'screens/request_success_screen.dart';
import 'screens/mechanic/mechanic_root_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 REQUIRED FOR FIREBASE
  await Firebase.initializeApp();

  runZonedGuarded(() => runApp(const MechResQApp()), (error, stack) {
    debugPrint('Uncaught Error: $error');
    debugPrintStack(stackTrace: stack);
  });
}

// ======================================================
// APP
// ======================================================

class MechResQApp extends StatelessWidget {
  const MechResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MechResQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.hazardTheme(),

      // Always start with Splash
      home: const SplashScreen(),

      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => LoginScreen(),
        '/forgot_password': (_) => ForgotPasswordScreen(),

        // REGISTER
        '/register_user': (_) => const UserRegisterScreen(),
        '/register_mechanic': (_) => const MechanicRegisterScreen(),
        '/shop_location_picker': (_) => ShopLocationPickerScreen(),

        // USER
        '/home': (_) => const MechanicListScreen(),
        '/profile': (_) => ProfileScreen(),
        '/my_requests': (_) => const MyRequestsScreen(),
        '/create_request': (_) => const CreateRequestScreen(),
        '/request_success': (context) {
          // RequestSuccessScreen reads arguments from ModalRoute.of(context) in its build method
          return const RequestSuccessScreen();
        },

        // MECHANIC
        '/mechanic_root': (_) => const MechanicRootScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

// ======================================================
// SPLASH (AUTH + ROLE DECIDER)
// ======================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _decideNavigation();
  }

  Future<void> _decideNavigation() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final isLoggedIn = await _auth.isLoggedIn();

    if (!isLoggedIn) {
      _go('/welcome');
      return;
    }

    final role = await _auth.getRole();

    if (role == 'mechanic') {
      _go('/mechanic_root');
    } else if (role == 'user') {
      _go('/home');
    } else {
      // Safety fallback
      await _auth.logout();
      _go('/welcome');
    }
  }

  void _go(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF263238),
      body: Center(
        child: Text(
          'MechResQ',
          style: TextStyle(
            fontSize: 36,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}