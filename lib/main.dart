import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme.dart';
import 'theme_controller.dart';
import 'core/locale_provider.dart';
import 'l10n/app_localizations.dart';
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

  final localeProvider = LocaleProvider();
  await localeProvider.init();

  runZonedGuarded(
    () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider.value(value: localeProvider),
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
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ───────── LOCALIZATION ─────────
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ───────── THEMES ─────────
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.hazardTheme(),
      themeMode: themeController.themeMode,

      // ───────── LOCALIZED TITLE SAFELY ─────────
      builder: (context, child) {
        final l10n = AppLocalizations.of(context);
        return Title(
          title: l10n?.appName ?? 'MechResQ',
          color: Theme.of(context).colorScheme.primary,
          child: child!,
        );
      },

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
        '/my_requests': (_) => MyRequestsScreen(),
        '/create_request': (_) => const CreateRequestScreen(),
        '/request_success': (_) => const RequestSuccessScreen(),
        '/settings': (_) => const SettingsScreen(),

        // MECHANIC
        '/mechanic_root': (_) => const MechanicRootScreen(),
      },

      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Scaffold(
              body: Center(
                child: Text(
                  l10n != null
                      ? '${l10n.error}: ${settings.name ?? "unknown"}'
                      : 'Route not found: ${settings.name}',
                ),
              ),
            );
          },
        );
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
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final isLoggedIn = await _auth.isLoggedIn();

    if (!isLoggedIn) {
      _go('/welcome');
      return;
    }

    final role = await _auth.getRole();

    switch (role) {
      case 'mechanic':
        _go('/mechanic_root');
        break;
      case 'user':
        _go('/home');
        break;
      default:
        await _auth.logout();
        _go('/welcome');
    }
  }

  void _go(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Text(
          l10n?.appName ?? 'MechResQ',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}
