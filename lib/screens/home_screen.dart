// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../services/mechanic_firestore_service.dart';
import '../services/auth_service.dart';
import 'mechanic_detail_screen.dart';
import '../widgets/mechanic_card.dart';
import 'my_requests_screen.dart';
import 'my_vehicles_screen.dart';
import 'profile_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import 'resq_assist_screen.dart';

enum SelectedSection { mechanics, requests, vehicles, help }

class MechanicListScreen extends StatefulWidget {
  const MechanicListScreen({super.key});

  @override
  State<MechanicListScreen> createState() => _MechanicListScreenState();
}

class _MechanicListScreenState extends State<MechanicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _auth = AuthService();
  final MechanicFirestoreService _mechanicService = MechanicFirestoreService();

  SelectedSection _selected = SelectedSection.mechanics;

  Map<String, dynamic>? _profile;

  // filter UI state
  int? _expYears; // e.g., 1,2,3...
  List<String> _selectedVehicleTypes = [];
  String? _priceRange; // e.g., "100-200"
  double? _maxDistanceKm;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
  try {
    final p = await _auth.getCurrentUserProfile(); // ✅ correct

    if (!mounted) return;

    setState(() {
      _profile = p != null ? Map<String, dynamic>.from(p) : null;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() => _profile = null);
  }
}

  /// Filter mechanics list by search query and filters
  List<Map<String, dynamic>> _filterMechanics(
    List<Map<String, dynamic>> mechanics,
  ) {
    var filtered = List<Map<String, dynamic>>.from(mechanics);

    // Apply search filter
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final name = (m['name'] ?? '').toString().toLowerCase();
        final shopName = (m['shopName'] ?? '').toString().toLowerCase();
        final vehicleTypes = (m['vehicleTypes'] as List? ?? [])
            .map((e) => e.toString().toLowerCase())
            .join(',');
        return name.contains(searchQuery) ||
            shopName.contains(searchQuery) ||
            vehicleTypes.contains(searchQuery);
      }).toList();
    }

    // Apply other filters
    if (_minRating != null) {
      filtered = filtered.where((m) {
        final rating = (m['rating'] ?? 0.0) as double;
        return rating >= _minRating!;
      }).toList();
    }

    if (_selectedVehicleTypes.isNotEmpty) {
      filtered = filtered.where((m) {
        final types = (m['vehicleTypes'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
        return _selectedVehicleTypes.any((vt) => types.contains(vt));
      }).toList();
    }

    // Note: experienceYears, priceRange, and distanceKm are not in Firestore schema
    // so those filters won't work until those fields are added to Firestore

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _expYears = null;
      _selectedVehicleTypes = [];
      _priceRange = null;
      _maxDistanceKm = null;
      _minRating = null;
      _searchController.clear();
    });
    // close endDrawer if open
    Navigator.of(context).maybePop();
  }

  void _applyFilters() {
    setState(() {});
    // close endDrawer if open
    Navigator.of(context).maybePop();
  }

  /// Convert Map<String, dynamic> to Map<String, String> for MechanicCard
 Map<String, String> _convertToCardFormat(Map<String, dynamic> mechanic) {
  final vehicleTypes = (mechanic['vehicleTypes'] as List? ?? [])
      .map((e) => e.toString())
      .toList();

  final rating = (mechanic['rating'] as num?)?.toDouble() ?? 0.0;
  final distanceKm = (mechanic['distanceKm'] as num?)?.toDouble() ?? 0.0;

  return {
    'id': mechanic['id']?.toString() ?? mechanic['uid']?.toString() ?? '',
    'name': mechanic['name']?.toString() ?? '',
    'shopName': mechanic['shopName']?.toString() ?? '',
    'address': mechanic['address']?.toString() ?? '',
    'experienceYears': (mechanic['experienceYears'] ?? 0).toString(),
    'vehicleTypes': vehicleTypes.join(', '), // ✅ clean UI
    'serviceTypes': (mechanic['serviceTypes'] as List? ?? [])
        .map((e) => e.toString())
        .join(', '),
    'priceRange': mechanic['priceRange']?.toString() ?? '',
    'rating': rating.toStringAsFixed(1),
    'distanceKm': distanceKm.toStringAsFixed(1),
    'phone': mechanic['phone']?.toString() ?? '',
  };
}


  Widget _buildMechanicTile(Map<String, dynamic> mechanic) {
    final map = _convertToCardFormat(mechanic);
    return MechanicCard(
      mechanic: map,
      // MechanicCard has onTap — tapping opens details
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MechanicDetailScreen(mechanic: map)),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // helper chips for vehicle types found across all mechanics
  List<String> _allVehicleTypes(List<Map<String, dynamic>> mechanics) {
    final s = <String>{};
    for (var m in mechanics) {
      final types = (m['vehicleTypes'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      s.addAll(types);
    }
    return s.toList();
  }

  void _selectSection(SelectedSection s) {
    Navigator.pop(context); // close drawer
    setState(() => _selected = s);
  }

  Future<void> _handleLogout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Widget _buildSelectedContent() {
    switch (_selected) {
      case SelectedSection.requests:
        // navigate to the dedicated screen (push) so it has its own AppBar
        // we return the mechanics view while pushing so AnimatedSwitcher has a child,
        // but we immediately push the screen.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_selected == SelectedSection.requests && mounted) {
            // push only once
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyRequestsScreen()),
            );
            // revert selection to mechanics so when user returns, home shows mechanics
            setState(() => _selected = SelectedSection.mechanics);
          }
        });
        return _buildMechanicsList();

      case SelectedSection.vehicles:
        return const MyVehiclesScreen(key: ValueKey('vehicles'));

      case SelectedSection.help:
        return const HelpWidget();

      case SelectedSection.mechanics:
        return _buildMechanicsList();
    }
  }

  // ================= SOS DIALOG =================
  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.sos, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choose an emergency action below.\n"
                "This feature will automatically share your location and vehicle details when enabled.",
                style: TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 16),

              // ================= AUTO INFO =================
              const Text(
                "Information to be shared",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              _infoRow(Icons.location_on, "Current Location"),
              _infoRow(Icons.directions_car, "Selected Vehicle"),
              _infoRow(Icons.access_time, "Time & Date"),

              const SizedBox(height: 16),

              // ================= CALL OPTIONS =================
              const Text(
                "Emergency Call Options",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _sosButton(
                icon: Icons.build,
                label: "Call Nearest Mechanic",
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showSnack("Calling nearest mechanic (future)");
                },
              ),

              _sosButton(
                icon: Icons.contact_phone,
                label: "Call Emergency Contact",
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showSnack("Calling emergency contact (future)");
                },
              ),

              _sosButton(
                icon: Icons.support_agent,
                label: "Call Support",
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _showSnack("Calling support (future)");
                },
              ),

              const SizedBox(height: 10),

              const Text(
                "⚠ Use SOS only in real emergency situations.",
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicsList() {
    return Padding(
      key: const ValueKey('mechanics'),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Search by name, shop or vehicle type (e.g., Car, Bike)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {}); // Trigger rebuild to clear search
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}), // Rebuild on search change
          ),
          const SizedBox(height: 12),

          // list with StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _mechanicService.getVerifiedMechanicsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No verified mechanics available.'),
                  );
                }

                final allMechanics = snapshot.data!;
                final filteredMechanics = _filterMechanics(allMechanics);

                if (filteredMechanics.isEmpty) {
                  return const Center(
                    child: Text('No mechanics found.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Stream will automatically update, just wait a bit
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.separated(
                    itemCount: filteredMechanics.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildMechanicTile(filteredMechanics[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = {
      SelectedSection.mechanics: 'Mechanics Nearby',
      SelectedSection.requests: 'My Requests',
      SelectedSection.vehicles: 'My Vehicles',
      SelectedSection.help: 'Help',
    }[_selected]!;

    // derive display name & email safely
    final displayName =
        (_profile != null && (_profile!['name'] ?? '').toString().isNotEmpty)
        ? _profile!['name'].toString()
        : 'Your Name';
    final displayEmail =
        (_profile != null && (_profile!['email'] ?? '').toString().isNotEmpty)
        ? _profile!['email'].toString()
        : 'user@example.com';

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),

        leading: Builder(
          builder: (ctx) => IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(initial, style: const TextStyle(color: Colors.black)),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),

        actions: _selected == SelectedSection.mechanics
            ? [
                // 🤖 ResQAssist AI Chatbot
                IconButton(
                  icon: const Icon(Icons.smart_toy_outlined),
                  tooltip: "ResQAssist",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ResQAssistScreen()),
                    );
                  },
                ),

                // 🔍 Filters
                Builder(
                  builder: (innerCtx) {
                    return IconButton(
                      icon: const Icon(Icons.filter_alt_outlined),
                      tooltip: 'Filters',
                      onPressed: () => Scaffold.of(innerCtx).openEndDrawer(),
                    );
                  },
                ),
              ]
            : null,
      ),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // yellow header with avatar + name + email
              Container(
                color: Colors.yellow[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // close drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayEmail,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Home item (shows mechanics list)
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _selected == SelectedSection.mechanics,
                onTap: () => _selectSection(SelectedSection.mechanics),
              ),

              // Drawer items (requested ones)
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('My Requests'),
                selected: _selected == SelectedSection.requests,
                onTap: () => _selectSection(SelectedSection.requests),
              ),
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: const Text('My Vehicles'),
                selected: _selected == SelectedSection.vehicles,
                onTap: () => _selectSection(SelectedSection.vehicles),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help'),
                selected: _selected == SelectedSection.help,
                onTap: () => _selectSection(SelectedSection.help),
              ),
              const Spacer(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              // 🚨 SOS CALL BUTTON
              ListTile(
                leading: const Icon(Icons.sos, color: Colors.red),
                title: const Text(
                  'SOS Call',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  _showSOSDialog(); // open SOS dialog
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleLogout();
                },
              ),
            ],
          ),
        ),
      ),

      // RIGHT-SIDE SLIDE PANEL (endDrawer) — Filters (kept intact)
      endDrawer: Drawer(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                // Experience
                const Text('Experience (years)'),
                const SizedBox(height: 6),
                DropdownButton<int?>(
                  isExpanded: true,
                  value: _expYears,
                  hint: const Text('Any'),
                  items: [null, 1, 2, 3, 4, 5, 6, 7].map((v) {
                    return DropdownMenuItem<int?>(
                      value: v,
                      child: Text(v == null ? 'Any' : '$v+ years'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _expYears = v),
                ),
                const SizedBox(height: 12),

                // Vehicle types (chips)
                const Text('Vehicle type'),
                const SizedBox(height: 6),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _mechanicService.getVerifiedMechanicsStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final vehicleTypes = _allVehicleTypes(snapshot.data!);
                    if (vehicleTypes.isEmpty) {
                      return const Text('No vehicle types available');
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vehicleTypes.map((vt) {
                          final selected = _selectedVehicleTypes.contains(vt);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: FilterChip(
                              label: Text(vt),
                              selected: selected,
                              onSelected: (s) {
                                setState(() {
                                  if (s) {
                                    _selectedVehicleTypes.add(vt);
                                  } else {
                                    _selectedVehicleTypes.remove(vt);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Price ranges
                const Text('Price range'),
                const SizedBox(height: 6),
                DropdownButton<String?>(
                  isExpanded: true,
                  value: _priceRange,
                  hint: const Text('Any'),
                  items:
                      <String?>[
                            null,
                            '100-200',
                            '150-250',
                            '200-300',
                            '300-500',
                          ]
                          .map(
                            (p) => DropdownMenuItem<String?>(
                              value: p,
                              child: Text(p ?? 'Any'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _priceRange = v),
                ),
                const SizedBox(height: 12),

                // Distance
                const Text('Max distance (km)'),
                const SizedBox(height: 6),
                DropdownButton<double?>(
                  isExpanded: true,
                  value: _maxDistanceNormalizer(_maxDistanceKm),
                  hint: const Text('Any'),
                  items: <double?>[null, 2.0, 5.0, 10.0].map((d) {
                    return DropdownMenuItem<double?>(
                      value: d,
                      child: Text(d == null ? 'Any' : '≤ ${d.toString()} km'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _maxDistanceKm = v),
                ),
                const SizedBox(height: 12),

                // Rating
                const Text('Minimum rating'),
                Slider(
                  min: 0,
                  max: 5,
                  divisions: 5,
                  value: _minRating ?? 0,
                  label: (_minRating ?? 0).toString(),
                  onChanged: (val) =>
                      setState(() => _minRating = val == 0 ? null : val),
                ),

                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _resetFilters();
                          Navigator.of(context).maybePop();
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _applyFilters(),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildSelectedContent(),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_request');
        },
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  // Normalizer: returns the same value. Created to avoid analyzer warnings for nullable generics in Dropdown
  double? _maxDistanceNormalizer(double? v) => v;

  // ================= SOS HELPERS =================

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _sosButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          minimumSize: const Size(double.infinity, 46),
          side: BorderSide(color: color),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
