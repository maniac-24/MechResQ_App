// lib/screens/mechanic/mechanic_root_screen.dart
import 'package:flutter/material.dart';

import 'mechanic_home_screen.dart';
import 'incoming_requests_screen.dart';
import 'active_service_screen.dart';
import 'service_history_screen.dart';
import 'earnings_screen.dart';
import 'mechanic_profile_screen.dart';

class MechanicRootScreen extends StatefulWidget {
  const MechanicRootScreen({super.key});

  @override
  State<MechanicRootScreen> createState() => _MechanicRootScreenState();
}

class _MechanicRootScreenState extends State<MechanicRootScreen> {
  int _currentIndex = 0;

  // 🔔 Temporary flags (replace with backend later)
  bool hasIncomingRequests = true;
  bool hasActiveService = true;

  @override
  Widget build(BuildContext context) {
    final screens = [
      MechanicHomeScreen(),
      _requestsTab(),
      EarningsScreen(),
      MechanicProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            label: "Requests",
            icon: Stack(
              children: [
                Icon(Icons.notifications_active),
                if (hasIncomingRequests || hasActiveService)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: "Earnings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ================= REQUESTS TAB =================
  Widget _requestsTab() {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Requests"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Incoming"),
              Tab(text: "Active"),
              Tab(text: "History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            IncomingRequestsScreen(),
            ActiveServiceScreen(),
            ServiceHistoryScreen(),
          ],
        ),
      ),
    );
  }
}
