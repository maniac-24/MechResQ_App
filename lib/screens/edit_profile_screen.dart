// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // PRIMARY INFO
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _dobC = TextEditingController();

  String _gender = "Male";
  List<String> _languages = ["English"];

  // OTHER INFO
  final _pincodeC = TextEditingController();
  final _cityC = TextEditingController();
  String _state = "Karnataka";

  final List<String> _languagesList = [
    "English",
    "Hindi",
    "Kannada",
    "Tamil",
    "Telugu",
    "Malayalam",
    "Bengali",
    "Marathi",
    "Gujarati",
    "Punjabi",
    "Odia",
    "Urdu",
  ];

  final List<String> _states = [
    "Andaman & Nicobar Islands",
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chandigarh",
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
    "Punjab",
    "Rajasthan",
    "Tamil Nadu",
    "Telangana",
    "Uttar Pradesh",
    "West Bengal",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ------------------------------------------------------------------
  // LANGUAGE SELECTOR (MULTI SELECT + SCROLL)
  // ------------------------------------------------------------------
  void _openLanguageSelector() {
    List<String> temp = List.from(_languages);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Languages"),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              itemCount: _languagesList.length,
              itemBuilder: (_, i) {
                final lang = _languagesList[i];
                return CheckboxListTile(
                  title: Text(lang),
                  value: temp.contains(lang),
                  onChanged: (v) {
                    setState(() {
                      v == true ? temp.add(lang) : temp.remove(lang);
                    });
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _languages = temp);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATE SELECTOR (SINGLE SELECT + SCROLL)
  // ------------------------------------------------------------------
  void _openStateSelector() {
    String temp = _state;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select State"),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.builder(
              itemCount: _states.length,
              itemBuilder: (_, i) {
                return RadioListTile<String>(
                  title: Text(_states[i]),
                  value: _states[i],
                  // ignore: duplicate_ignore
                  // ignore: deprecated_member_use
                  groupValue: temp,
                  onChanged: (v) {
                    setState(() => temp = v!);
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _state = temp);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DATE PICKER
  // ------------------------------------------------------------------
  void _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobC.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: yellow,
          tabs: const [
            Tab(text: "Primary"),
            Tab(text: "Other Info"),
            Tab(text: "Settings"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_primaryTab(), _otherInfoTab(), _settingsTab()],
      ),
    );
  }

  // ------------------------------------------------------------------
  // TABS
  // ------------------------------------------------------------------
  Widget _primaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _input("Full Name", _nameC),
          _input("Email", _emailC),
          _input("Phone", _phoneC),
          _dropdown(
            label: "Gender",
            value: _gender,
            items: ["Male", "Female", "Other"],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          _picker("Languages", _languages.join(", "), _openLanguageSelector),
          _picker(
            "DOB",
            _dobC.text.isEmpty ? "Select Date" : _dobC.text,
            _pickDOB,
          ),
        ],
      ),
    );
  }

  Widget _otherInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _input("Pincode", _pincodeC),
          _input("City", _cityC),
          _picker("State", _state, _openStateSelector),
        ],
      ),
    );
  }

  Widget _settingsTab() {
    return const Center(child: Text("Settings coming soon"));
  }

  // ------------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------------
  Widget _input(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _picker(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}
