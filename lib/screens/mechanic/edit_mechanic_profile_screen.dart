import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../shop_location_picker_screen.dart';

/// ============================================================================
/// EDIT MECHANIC PROFILE SCREEN - PRODUCTION READY
/// ============================================================================
/// Full profile editing with Firestore sync, theme-compatible UI,
/// proper validation, and error handling.
/// ============================================================================
class EditMechanicProfileScreen extends StatefulWidget {
  const EditMechanicProfileScreen({super.key});

  @override
  State<EditMechanicProfileScreen> createState() =>
      _EditMechanicProfileScreenState();
}

class _EditMechanicProfileScreenState extends State<EditMechanicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH / FIRESTORE
  // ═══════════════════════════════════════════════════════════════════════════
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  bool _saving = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY
  // ═══════════════════════════════════════════════════════════════════════════
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _dobC = TextEditingController();

  DateTime? _dob; // ✅ CRITICAL FIX: Store actual date for Firestore
  String _gender = "Male";
  List<String> _languages = ["English"];

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFESSIONAL
  // ═══════════════════════════════════════════════════════════════════════════
  final _garageNameC = TextEditingController();
  final _experienceC = TextEditingController();
  final _serviceRadiusC = TextEditingController();
  List<String> _vehicleTypes = ["Bike"];
  List<String> _services = [];

  // ═══════════════════════════════════════════════════════════════════════════
  // SHOP LOCATION
  // ═══════════════════════════════════════════════════════════════════════════
  double? _shopLat;
  double? _shopLng;
  String? _shopAddress;
  bool _updatingShopLocation = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // OTHER
  // ═══════════════════════════════════════════════════════════════════════════
  final _pincodeC = TextEditingController();
  final _cityC = TextEditingController();
  String _state = "Karnataka";

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  final List<String> _languageOptions = [
    "English",
    "Hindi",
    "Kannada",
    "Tamil",
    "Telugu",
    "Malayalam",
    "Marathi",
    "Bengali",
  ];

  final List<String> _vehicleOptions = [
    "Bike",
    "Car",
    "EV",
    "Auto",
    "Truck",
  ];

  final List<String> _serviceOptions = [
    'Engine Repair & Servicing',
    'Battery & Electrical',
    'Tyre Change & Puncture',
    'Oil & Fluid Change',
    'General Maintenance',
  ];

  final List<String> _states = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Delhi",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Tamil Nadu",
    "Telangana",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _dobC.dispose();
    _garageNameC.dispose();
    _experienceC.dispose();
    _serviceRadiusC.dispose();
    _pincodeC.dispose();
    _cityC.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD PROFILE FROM FIRESTORE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final doc = await _firestore.collection('mechanics').doc(uid).get();
      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile not found'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final d = doc.data()!;
      setState(() {
        // Primary
        _nameC.text = d['name'] ?? '';
        _emailC.text = d['email'] ?? '';
        _phoneC.text = d['phone'] ?? '';
        _gender = d['gender'] ?? 'Male';
        
        // ✅ Handle DOB (could be Timestamp or String)
        if (d['dateOfBirth'] is Timestamp) {
          _dob = (d['dateOfBirth'] as Timestamp).toDate();
          _dobC.text = "${_dob!.day.toString().padLeft(2, '0')}/"
              "${_dob!.month.toString().padLeft(2, '0')}/"
              "${_dob!.year}";
        } else if (d['dateOfBirth'] is String) {
          _dobC.text = d['dateOfBirth'];
        }
        
        // Handle languages (may be stored as string or array)
        if (d['languages'] is List) {
          _languages = List<String>.from(d['languages']);
        } else if (d['languages'] is String) {
          _languages = (d['languages'] as String).split(',').map((e) => e.trim()).toList();
        }

        // Professional
        _garageNameC.text = d['shopName'] ?? d['garageName'] ?? '';
        _experienceC.text = d['experienceYears']?.toString() ?? '';
        _serviceRadiusC.text = d['serviceRadius']?.toString() ?? '';
        
        // Handle vehicle types (may be stored as string or array)
        if (d['vehicleTypes'] is List) {
          _vehicleTypes = List<String>.from(d['vehicleTypes']);
        } else if (d['vehicleTypes'] is String) {
          _vehicleTypes = (d['vehicleTypes'] as String).split(',').map((e) => e.trim()).toList();
        }

        // Handle services (array)
        if (d['services'] is List) {
          _services = List<String>.from(d['services']);
        }

        // Shop location
        _shopLat = d['shopLat'];
        _shopLng = d['shopLng'];
        _shopAddress = d['shopAddress'];

        // Other
        _pincodeC.text = d['pincode'] ?? '';
        _cityC.text = d['city'] ?? '';
        _state = d['state'] ?? 'Karnataka';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE PROFILE TO FIRESTORE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // ── Validation ────────────────────────────────────────────────────────────
    if (_nameC.text.trim().isEmpty) {
      _showError('Name is required');
      _tabController.animateTo(0);
      return;
    }

    // ✅ Email validation (if provided)
    if (_emailC.text.trim().isNotEmpty &&
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_emailC.text.trim())) {
      _showError('Enter a valid email address');
      _tabController.animateTo(0);
      return;
    }

    // ✅ Phone validation (Indian format)
    final phone = _phoneC.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showError('Enter a valid 10-digit phone number');
      _tabController.animateTo(0);
      return;
    }

    if (_garageNameC.text.trim().isEmpty) {
      _showError('Garage name is required');
      _tabController.animateTo(1);
      return;
    }

    if (_services.isEmpty) {
      _showError('Select at least one service');
      _tabController.animateTo(1);
      return;
    }

    setState(() => _saving = true);

    try {
      await _firestore.collection('mechanics').doc(uid).update({
        // Primary
        'name': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'phone': _phoneC.text.trim(),
        'gender': _gender,
        'dateOfBirth': _dob != null ? Timestamp.fromDate(_dob!) : null, // ✅ FIXED
        'languages': _languages,

        // Professional
        'shopName': _garageNameC.text.trim(),
        'experienceYears': int.tryParse(_experienceC.text.trim()) ?? 0,
        'vehicleTypes': _vehicleTypes,
        'services': _services,
        'serviceRadius': double.tryParse(_serviceRadiusC.text.trim()) ?? 10.0,

        // Other
        'pincode': _pincodeC.text.trim(),
        'city': _cityC.text.trim(),
        'state': _state,

        // Metadata
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.secondary, // ✅ Theme-aware
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EDIT SHOP LOCATION
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _editShopLocation() async {
    final mechanicId = _auth.currentUser?.uid;
    if (mechanicId == null) return;

    try {
      final result = await Navigator.push<ShopLocationResult>(
        context,
        MaterialPageRoute(
          builder: (_) => ShopLocationPickerScreen(),
        ),
      );

      if (result == null) return;

      setState(() => _updatingShopLocation = true);

      await _firestore.collection('mechanics').doc(mechanicId).update({
        'shopLat': result.latitude,
        'shopLng': result.longitude,
        'shopAddress': result.shopAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _shopLat = result.latitude;
        _shopLng = result.longitude;
        _shopAddress = result.shopAddress;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Shop location updated"),
          backgroundColor: Theme.of(context).colorScheme.secondary, // ✅ FIXED: Theme-aware
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update location: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingShopLocation = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE PICKER
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dob = picked; // ✅ CRITICAL FIX: Store for Firestore
        _dobC.text = "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTI SELECT DIALOG (THEME-AWARE)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _multiSelectDialog({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onConfirm,
  }) async {
    final Set<String> tempSelected = selectedValues.toSet();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: SizedBox(
                width: 350,
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((item) {
                    return CheckboxListTile(
                      title: Text(
                        item,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      value: tempSelected.contains(item),
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (checked) {
                        setDialogState(() {
                          checked == true
                              ? tempSelected.add(item)
                              : tempSelected.remove(item);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    onConfirm(tempSelected.toList());
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Edit Mechanic Profile"),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Mechanic Profile"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Primary"),
            Tab(text: "Professional"),
            Tab(text: "Other Info"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _primaryTab(),
                _professionalTab(),
                _otherTab(),
              ],
            ),
          ),
          
          // ── Save Button ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        "Save Profile",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMARY TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _primaryTab() {
    return _section([
      _input("Full Name *", _nameC),
      _input("Email", _emailC),
      _input("Phone *", _phoneC, type: TextInputType.phone),
      DropdownButtonFormField<String>(
        value: _gender,
        items: ["Male", "Female", "Others"]
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _gender = v!),
        decoration: _decoration("Gender"),
        dropdownColor: Theme.of(context).cardColor,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      _chipSelector(
        label: "Languages",
        values: _languages,
        onAdd: () => _multiSelectDialog(
          title: "Select Languages",
          options: _languageOptions,
          selectedValues: _languages,
          onConfirm: (v) => setState(() => _languages = v),
        ),
        onRemove: (v) => setState(() => _languages.remove(v)),
      ),
      TextField(
        controller: _dobC,
        readOnly: true,
        onTap: _pickDOB,
        decoration: _decoration("Date of Birth"),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHIP SELECTOR (THEME-AWARE)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _chipSelector({
    required String label,
    required List<String> values,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...values.map(
              (v) => Chip(
                label: Text(v),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => onRemove(v),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              onPressed: onAdd,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFESSIONAL TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _professionalTab() {
    return _section([
      _input("Garage Name *", _garageNameC),
      _input("Experience (Years)", _experienceC, type: TextInputType.number),
      _chipSelector(
        label: "Vehicle Types",
        values: _vehicleTypes,
        onAdd: () => _multiSelectDialog(
          title: "Vehicle Types",
          options: _vehicleOptions,
          selectedValues: _vehicleTypes,
          onConfirm: (v) => setState(() => _vehicleTypes = v),
        ),
        onRemove: (v) => setState(() => _vehicleTypes.remove(v)),
      ),
      _chipSelector(
        label: "Services Offered *",
        values: _services,
        onAdd: () => _multiSelectDialog(
          title: "Services Offered",
          options: _serviceOptions,
          selectedValues: _services,
          onConfirm: (v) => setState(() => _services = v),
        ),
        onRemove: (v) => setState(() => _services.remove(v)),
      ),
      _input("Service Radius (KM)", _serviceRadiusC, type: TextInputType.number),
      const Divider(height: 32),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.location_on,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          "Shop Location",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _shopAddress ?? "Location not set",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: _updatingShopLocation
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : TextButton(
                onPressed: _editShopLocation,
                child: Text(
                  "Edit",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OTHER TAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _otherTab() {
    return _section([
      _input("Pincode", _pincodeC, type: TextInputType.number),
      _input("City", _cityC),
      DropdownButtonFormField<String>(
        value: _state,
        items: _states
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _state = v!),
        decoration: _decoration("State"),
        dropdownColor: Theme.of(context).cardColor,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _section(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: children
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: e,
                ))
            .toList(),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: _decoration(label),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }
}