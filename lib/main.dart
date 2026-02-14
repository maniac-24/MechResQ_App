import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme.dart';
import 'theme_controller.dart';
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
import 'screens/settings_screen.dart';
import 'screens/mechanic/mechanic_root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await initializeDateFormatting();

  runZonedGuarded(
    () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const MechResQApp(),
      ),
    ),
    (error, stack) {
      debugPrint('Uncaught Error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

// ======================================================
// APP ROOT
// ======================================================

class MechResQApp extends StatelessWidget {
  const MechResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.hazardTheme(),
      themeMode: themeController.themeMode,
      home: const SplashScreen(),
      routes: {
        '/welcome': (_) => const WelcomeScreen(),
        '/login': (_) => LoginScreen(),
        '/forgot_password': (_) => ForgotPasswordScreen(),
        '/register_user': (_) => const UserRegisterScreen(),
        '/register_mechanic': (_) => const MechanicRegisterScreen(),
        '/shop_location_picker': (_) => ShopLocationPickerScreen(),
        '/home': (_) => const MechanicListScreen(),
        '/profile': (_) => ProfileScreen(),
        '/my_requests': (_) => MyRequestsScreen(),
        '/create_request': (_) => const CreateRequestScreen(),
        '/request_success': (_) => const RequestSuccessScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/mechanic_root': (_) => const MechanicRootScreen(),
      },
    );
  }
}

// ======================================================
// SPLASH SCREEN
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
    // Small splash delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final isLoggedIn = _auth.isLoggedIn();

    if (!isLoggedIn) {
      _navigate('/welcome');
      return;
    }

    final role = await _auth.getRole();

    if (!mounted) return;

    switch (role) {
      case 'mechanic':
        _navigate('/mechanic_root');
        break;
      case 'user':
        _navigate('/home');
        break;
      default:
        await _auth.logout();
        _navigate('/welcome');
    }
  }

  void _navigate(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'MechResQ',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
