// lib/screens/mechanic/mechanic_root_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';

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
  
  // Notification badge streams
  late final StreamController<int> _incomingRequestsCountController;
  late final StreamController<int> _activeServiceCountController;
  
  // Track backend subscriptions for proper cleanup
  final List<StreamSubscription> _subscriptions = [];
  
  @override
  void initState() {
    super.initState();
    _incomingRequestsCountController = StreamController<int>.broadcast();
    _activeServiceCountController = StreamController<int>.broadcast();
    
    // TODO: Wire these to your actual backend/state management
    // For now, simulate with mock data
    _simulateBadgeUpdates();
  }
  
  @override
  void dispose() {
    // Cancel all backend subscriptions first
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    
    // Then close stream controllers
    _incomingRequestsCountController.close();
    _activeServiceCountController.close();
    super.dispose();
  }
  
  // TODO: Replace with actual backend listeners
  void _simulateBadgeUpdates() {
    // Example: Listen to your service/repository streams here
    // final sub = _requestService.incomingRequestsStream.listen((requests) {
    //   _incomingRequestsCountController.add(requests.length);
    // });
    // _subscriptions.add(sub);
    
    // Mock data for demonstration:
    _incomingRequestsCountController.add(3);
    _activeServiceCountController.add(1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const MechanicHomeScreen(),
      _requestsTab(),
      const EarningsScreen(),
      MechanicProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Handle back navigation: return to home tab if not already there
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          // On home tab: show exit confirmation
          final shouldExit = await _showExitConfirmation();
          if (shouldExit == true && context.mounted) {
            // SystemNavigator.pop() only works on Android
            // iOS doesn't allow programmatic app exits per Apple HIG
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: StreamBuilder<int>(
          stream: _incomingRequestsCountController.stream,
          initialData: 0,
          builder: (context, incomingSnapshot) {
            return StreamBuilder<int>(
              stream: _activeServiceCountController.stream,
              initialData: 0,
              builder: (context, activeSnapshot) {
                final incomingCount = incomingSnapshot.data ?? 0;
                final activeCount = activeSnapshot.data ?? 0;
                final totalRequestsBadge = incomingCount + activeCount;
                
                return BottomNavigationBar(
                  currentIndex: _currentIndex,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  unselectedItemColor:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onTap: (index) => setState(() => _currentIndex = index),
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: _buildBadgedIcon(
                        Icons.notifications_active,
                        totalRequestsBadge,
                      ),
                      label: "Requests",
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet),
                      label: "Earnings",
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: "Profile",
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ================= REQUESTS TAB =================
  Widget _requestsTab() {
    return _RequestsTabContent(
      incomingCountStream: _incomingRequestsCountController.stream,
      activeCountStream: _activeServiceCountController.stream,
    );
  }
  
  // ================= BADGE WIDGET =================
  Widget _buildBadgedIcon(IconData icon, int count) {
    if (count == 0) {
      return Icon(icon);
    }
    
    final scheme = Theme.of(context).colorScheme;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                color: scheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
  
  // ================= EXIT CONFIRMATION =================
  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

/// Holds TabController so we can switch to Active tab when mechanic accepts from preview.
class _RequestsTabContent extends StatefulWidget {
  final Stream<int> incomingCountStream;
  final Stream<int> activeCountStream;
  
  const _RequestsTabContent({
    required this.incomingCountStream,
    required this.activeCountStream,
  });

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
          tabs: [
            _buildTabWithBadge("Incoming", widget.incomingCountStream),
            _buildTabWithBadge("Active", widget.activeCountStream),
            const Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          IncomingRequestsScreen(onSwitchToActiveTab: _switchToActiveTab),
          const ActiveServiceScreen(),
          const ServiceHistoryScreen(),
        ],
      ),
    );
  }
  
  Widget _buildTabWithBadge(String label, Stream<int> countStream) {
    return StreamBuilder<int>(
      stream: countStream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        
        if (count == 0) {
          return Tab(text: label);
        }
        
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}