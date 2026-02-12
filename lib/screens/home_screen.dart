// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

import '../services/mechanic_firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'mechanic_detail_screen.dart';
import '../widgets/mechanic_card.dart';
import '../screens/help_screen.dart';
import 'my_vehicles_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'resq_assist_screen.dart';

enum SelectedSection { mechanics, vehicles, help }

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
      final p = await _auth.getCurrentUserProfile();

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
      'vehicleTypes': vehicleTypes.join(', '),
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

  /// Navigate to My Requests screen (separate flow, not a tab)
  void _openMyRequests() {
    Navigator.pop(context); // close drawer
    Navigator.pushNamed(context, '/my_requests');
  }

  Future<void> _handleLogout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
  }

  Widget _buildSelectedContent() {
    switch (_selected) {
      case SelectedSection.vehicles:
        return const MyVehiclesScreen(key: ValueKey('vehicles'));

      case SelectedSection.help:
        return HelpScreen();

      case SelectedSection.mechanics:
        return _buildMechanicsList();
    }
  }

  // ================= SOS DIALOG =================
  void _showSOSDialog() {
    final scheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Row(
          children: [
            Icon(Icons.sos, color: scheme.error),
            const SizedBox(width: 8),
            Text(
              'Emergency SOS',
              style: TextStyle(color: scheme.onSurface),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose an emergency action below.\n"
                "This feature will automatically share your location and vehicle details when enabled.",
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 16),

              // ================= AUTO INFO =================
              Text(
                "Information to be shared",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),

              _infoRow(Icons.location_on, "Current Location"),
              _infoRow(Icons.directions_car, "Selected Vehicle"),
              _infoRow(Icons.access_time, "Time & Date"),

              const SizedBox(height: 16),

              // ================= CALL OPTIONS =================
              Text(
                "Emergency Call Options",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              _sosButton(
                icon: Icons.build,
                label: "Call Nearest Mechanic",
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
                onTap: () {
                  Navigator.pop(context);
                  SnackBarHelper.showInfo(
                    context,
                    "Calling nearest mechanic (feature coming soon)",
                  );
                },
              ),

              _sosButton(
                icon: Icons.contact_phone,
                label: "Call Emergency Contact",
                background: scheme.secondaryContainer,
                foreground: scheme.onSecondaryContainer,
                onTap: () {
                  Navigator.pop(context);
                  SnackBarHelper.showInfo(
                    context,
                    "Calling emergency contact (feature coming soon)",
                  );
                },
              ),

              _sosButton(
                icon: Icons.support_agent,
                label: "Call Support",
                background: scheme.primaryContainer,
                foreground: scheme.onPrimaryContainer,
                onTap: () {
                  Navigator.pop(context);
                  SnackBarHelper.showInfo(
                    context,
                    "Calling support (feature coming soon)",
                  );
                },
              ),

              const SizedBox(height: 10),

              Text(
                "⚠ Use SOS only in real emergency situations.",
                style: TextStyle(
                  color: scheme.error,
                  fontSize: 12,
                ),
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
    final scheme = Theme.of(context).colorScheme;
    
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
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // list with StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _mechanicService.getVerifiedMechanicsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: scheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: scheme.error),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No verified mechanics available.',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  );
                }

                final allMechanics = snapshot.data!;
                final filteredMechanics = _filterMechanics(allMechanics);

                if (filteredMechanics.isEmpty) {
                  return Center(
                    child: Text(
                      'No mechanics found.',
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.separated(
                    itemCount: filteredMechanics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final scheme = Theme.of(context).colorScheme;
    
    final title = {
      SelectedSection.mechanics: 'Mechanics Nearby',
      SelectedSection.vehicles: 'My Vehicles',
      SelectedSection.help: 'Help & Support',
    }[_selected]!;

    // derive display name & email safely
    final displayName =
        (_profile != null && (_profile!['name'] ?? '').toString().isNotEmpty)
            ? _profile!['name'].toString()
            : 'Your Name';
    final displayEmail = (_profile != null &&
            (_profile!['email'] ?? '').toString().isNotEmpty)
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
              backgroundColor: scheme.secondary,
              child: Text(
                initial,
                style: TextStyle(
                  color: scheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              // Header with avatar + name + email
              Container(
                color: scheme.primary,
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
                        backgroundColor: scheme.onPrimary,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 28,
                            color: scheme.primary,
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
                            style: TextStyle(
                              fontSize: 16,
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              color: scheme.onPrimary.withOpacity(0.8),
                            ),
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

              // Drawer items
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('My Requests'),
                onTap: _openMyRequests,
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
                leading: Icon(Icons.sos, color: scheme.error),
                title: Text(
                  'SOS Call',
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // close drawer
                  _showSOSDialog();
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

      // RIGHT-SIDE SLIDE PANEL (endDrawer) — Filters
      endDrawer: _selected == SelectedSection.mechanics
          ? Drawer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                                final selected =
                                    _selectedVehicleTypes.contains(vt);
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
                        items: <String?>[
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
                        value: _maxDistanceKm,
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
                              onPressed: _resetFilters,
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _applyFilters,
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
            )
          : null,

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildSelectedContent(),
      ),

      floatingActionButton: _selected == SelectedSection.mechanics
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create_request');
              },
              backgroundColor: scheme.primary,
              child: Icon(Icons.add, color: scheme.onPrimary),
            )
          : null,
    );
  }

  // ================= SOS HELPERS =================

  Widget _infoRow(IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: scheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(double.infinity, 46),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}