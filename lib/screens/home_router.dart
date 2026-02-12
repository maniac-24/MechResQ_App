import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';

/// User role constants for type-safe role checking
class UserRoles {
  UserRoles._(); // Private constructor to prevent instantiation
  
  static const String mechanic = 'mechanic';
  static const String user = 'user';
}

/// Production-safe authentication router with proper lifecycle handling
/// 
/// Features:
/// - Post-frame navigation (prevents timing issues)
/// - Role-based routing with fallback handling
/// - Theme-aware loading indicator
/// - Proper error handling for corrupted/unknown roles
class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  @override
  void initState() {
    super.initState();
    // Defer navigation until after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final loggedIn = await TokenStorage.isLoggedIn();
    final role = await TokenStorage.getRole();

    if (!mounted) return;

    // Not logged in or role missing → Login screen
    if (!loggedIn || role == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      return;
    }

    // Role-based routing with fallback for unknown roles
    switch (role) {
      case UserRoles.mechanic:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/mechanic_root',
          (_) => false,
        );
        break;

      case UserRoles.user:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
        );
        break;

      default:
        // Unknown/corrupted role → Clear auth and redirect to login
        await TokenStorage.clear();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: scheme.primary,
        ),
      ),
    );
  }
}