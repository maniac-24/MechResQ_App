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
    return _RequestsTabContent();
  }
}

/// Holds TabController so we can switch to Active tab when mechanic accepts from preview.
class _RequestsTabContent extends StatefulWidget {
  @override
  State<_RequestsTabContent> createState() => _RequestsTabContentState();
}

class _RequestsTabContentState extends State<_RequestsTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToActiveTab() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Requests"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Incoming"),
            Tab(text: "Active"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IncomingRequestsScreen(onSwitchToActiveTab: _switchToActiveTab),
          ActiveServiceScreen(),
          ServiceHistoryScreen(),
        ],
      ),
    );
  }
}
