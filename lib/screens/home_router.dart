import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await TokenStorage.isLoggedIn();
    final role = await TokenStorage.getRole();

    if (!mounted) return;

    if (!loggedIn || role == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    // 👨‍🔧 MECHANIC
    if (role == 'mechanic') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/mechanic_root',
        (route) => false,
      );
    }
    // 👤 USER
    else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
