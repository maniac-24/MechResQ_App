import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../shop_location_picker_screen.dart';

class EditMechanicProfileScreen extends StatefulWidget {
  const EditMechanicProfileScreen({super.key});

  @override
  State<EditMechanicProfileScreen> createState() =>
      _EditMechanicProfileScreenState();
}

class _EditMechanicProfileScreenState extends State<EditMechanicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ================= AUTH / FIRESTORE =================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= PRIMARY =================
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _dobC = TextEditingController();

  String _gender = "Male";
  List<String> _languages = ["English"];

  // ================= PROFESSIONAL =================
  final _garageNameC = TextEditingController();
  final _experienceC = TextEditingController();
  final _serviceRadiusC = TextEditingController();
  List<String> _vehicleTypes = ["Bike"];

  // ================= SHOP LOCATION =================
  double? _shopLat;
  double? _shopLng;
  String? _shopAddress;
  bool _updatingShopLocation = false;

  // ================= OTHER =================
  final _pincodeC = TextEditingController();
  final _cityC = TextEditingController();
  String _state = "Karnataka";

  // ================= OPTIONS =================
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

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('mechanics').doc(uid).get();
    if (!doc.exists) return;

    final d = doc.data()!;
    setState(() {
      _nameC.text = d['name'] ?? '';
      _emailC.text = d['email'] ?? '';
      _phoneC.text = d['phone'] ?? '';
      _garageNameC.text = d['garageName'] ?? '';
      _experienceC.text = d['experienceYears']?.toString() ?? '';
      _serviceRadiusC.text = d['serviceRadius']?.toString() ?? '';
      _shopLat = d['shopLat'];
      _shopLng = d['shopLng'];
      _shopAddress = d['shopAddress'];
    });
  }

  // ================= EDIT SHOP LOCATION =================
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
        const SnackBar(content: Text("Shop location updated")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update location: $e")),
      );
    } finally {
      if (mounted) setState(() => _updatingShopLocation = false);
    }
  }

  // ================= DATE PICKER =================
  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobC.text =
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  // ================= MULTI SELECT =================
  Future<void> _multiSelectDialog({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onConfirm,
  }) async {
    final Set<String> tempSelected = selectedValues.toSet();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 350,
            child: ListView(
              shrinkWrap: true,
              children: options.map((item) {
                return CheckboxListTile(
                  title: Text(item),
                  value: tempSelected.contains(item),
                  onChanged: (checked) {
                    setState(() {
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
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm(tempSelected.toList());
                Navigator.pop(context);
              },
              child: const Text("Done"),
            ),
          ],
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint("PROFILE SAVED");
                },
                child: const Text("Save Profile"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PRIMARY TAB =================
  Widget _primaryTab() {
    return _section([
      _input("Full Name *", _nameC),
      _input("Email", _emailC),
      _input("Phone *", _phoneC, type: TextInputType.phone),
      DropdownButtonFormField<String>(
        initialValue: _gender,
        items: ["Male", "Female", "Others"]
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: (v) => setState(() => _gender = v!),
        decoration: _decoration("Gender"),
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
      ),
    ]);
  }
  Widget _chipSelector({
    required String label,
    required List<String> values,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...values.map(
              (v) => Chip(
                label: Text(v),
                onDeleted: () => onRemove(v),
              ),
            ),
            ActionChip(
              label: const Text('+ Add'),
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }

  // ================= PROFESSIONAL TAB =================
  Widget _professionalTab() {
    return _section([
      _input("Garage Name *", _garageNameC),
      _input("Experience (Years)", _experienceC,
          type: TextInputType.number),
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
      _input("Service Radius (KM)", _serviceRadiusC,
          type: TextInputType.number),
      const Divider(height: 32),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.location_on),
        title: const Text(
          "Shop Location",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _shopAddress ?? "Location not set",
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: _updatingShopLocation
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _editShopLocation,
                child: const Text("Edit"),
              ),
      ),
    ]);
  }

  // ================= OTHER TAB =================
  Widget _otherTab() {
    return _section([
      _input("Pincode", _pincodeC, type: TextInputType.number),
      _input("City", _cityC),
      DropdownButtonFormField<String>(
        initialValue: _state,
        items: _states
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (v) => setState(() => _state = v!),
        decoration: _decoration("State"),
      ),
    ]);
  }

  // ================= HELPERS =================
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

  Widget _input(String label, TextEditingController c,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: _decoration(label),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}