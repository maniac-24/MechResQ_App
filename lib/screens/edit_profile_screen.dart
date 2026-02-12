import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/snackbar_helper.dart';

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

  // SETTINGS (account-specific only)
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _serviceReminders = true;
  bool _promotionalOffers = false;
  bool _twoFactorAuth = false;
  bool _biometricLogin = false;

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

  @override
  void dispose() {
    _tabController.dispose();
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _dobC.dispose();
    _pincodeC.dispose();
    _cityC.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // LANGUAGE SELECTOR
  // ------------------------------------------------------------------
  void _openLanguageSelector() {
    showDialog(
      context: context,
      builder: (_) => _LanguageDialog(
        initial: List.from(_languages),
        allLanguages: _languagesList,
        onSave: (selected) {
          setState(() => _languages = selected);
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATE SELECTOR
  // ------------------------------------------------------------------
  void _openStateSelector() {
    showDialog(
      context: context,
      builder: (_) => _StateDialog(
        initial: _state,
        allStates: _states,
        onSave: (selected) {
          setState(() => _state = selected);
        },
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
      final formatter = DateFormat('dd/MM/yyyy');
      setState(() {
        _dobC.text = formatter.format(picked);
      });
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
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
          _picker(
            "Languages Known",
            _languages.join(", "),
            _openLanguageSelector,
          ),
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
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- MY NOTIFICATIONS (account-level) ---
          _sectionHeader("My Notifications", Icons.notifications_outlined),
          _settingSwitch(
            "Email Notifications",
            "Receive service updates via email",
            _emailNotifications,
            (v) => setState(() => _emailNotifications = v),
          ),
          _settingSwitch(
            "SMS Notifications",
            "Receive service updates via SMS",
            _smsNotifications,
            (v) => setState(() => _smsNotifications = v),
          ),
          _settingSwitch(
            "Service Reminders",
            "Reminders for upcoming / overdue services",
            _serviceReminders,
            (v) => setState(() => _serviceReminders = v),
          ),
          _settingSwitch(
            "Promotional Offers",
            "Exclusive deals and discounts",
            _promotionalOffers,
            (v) => setState(() => _promotionalOffers = v),
          ),

          const SizedBox(height: 24),

          // --- ACCOUNT SECURITY ---
          _sectionHeader("Account Security", Icons.security_outlined),
          _settingSwitch(
            "Two-Factor Authentication",
            "Extra security via OTP on login",
            _twoFactorAuth,
            (v) => setState(() => _twoFactorAuth = v),
          ),
          _settingSwitch(
            "Biometric Login",
            "Use fingerprint or face ID",
            _biometricLogin,
            (v) => setState(() => _biometricLogin = v),
          ),
          _settingTile(
            "Change Password",
            "Update your account password",
            Icons.lock_outline,
            () => SnackBarHelper.showInfo(
              context,
              "Opening change password...",
            ),
          ),

          const SizedBox(height: 24),

          // --- ACCOUNT ACTIONS ---
          _sectionHeader("Account", Icons.person_outline),
          _settingTile(
            "Linked Vehicles",
            "Manage vehicles linked to this account",
            Icons.directions_car_outlined,
            () => SnackBarHelper.showInfo(
              context,
              "Opening linked vehicles...",
            ),
          ),
          _settingTile(
            "Delete Account",
            "Permanently remove your account",
            Icons.delete_forever_outlined,
            () => _confirmDeleteAccount(),
            color: scheme.error,
          ),

          const SizedBox(height: 28),

          // SAVE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => SnackBarHelper.showSuccess(
                context,
                "Settings saved ✅",
              ),
              child: const Text(
                "Save Settings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SETTINGS HELPERS
  // ------------------------------------------------------------------
  Widget _sectionHeader(String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final scheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: scheme.primary,
        inactiveThumbColor: scheme.outline,
        inactiveTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _settingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: color),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: scheme.onSurface.withOpacity(0.6),
        ),
        onTap: onTap,
      ),
    );
  }

  void _confirmDeleteAccount() {
    final scheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          "Delete Account",
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          "This will permanently delete your account and all associated data. "
          "This action cannot be undone.",
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              Navigator.pop(context);
              SnackBarHelper.showWarning(
                context,
                "Account deletion requested",
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // PRIMARY / OTHER INFO HELPERS
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
        value: value,
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
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(value),
        ),
      ),
    );
  }
}

// ==================================================================
// LANGUAGE DIALOG
// ==================================================================
class _LanguageDialog extends StatefulWidget {
  final List<String> initial;
  final List<String> allLanguages;
  final ValueChanged<List<String>> onSave;

  const _LanguageDialog({
    required this.initial,
    required this.allLanguages,
    required this.onSave,
  });

  @override
  State<_LanguageDialog> createState() => __LanguageDialogState();
}

class __LanguageDialogState extends State<_LanguageDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      backgroundColor: scheme.surface,
      title: Text(
        "Languages Known",
        style: TextStyle(color: scheme.onSurface),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            itemCount: widget.allLanguages.length,
            itemBuilder: (_, i) {
              final lang = widget.allLanguages[i];
              return CheckboxListTile(
                title: Text(
                  lang,
                  style: TextStyle(color: scheme.onSurface),
                ),
                value: _selected.contains(lang),
                activeColor: scheme.primary,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(lang);
                    } else {
                      _selected.remove(lang);
                    }
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
            widget.onSave(_selected);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

// ==================================================================
// STATE DIALOG
// ==================================================================
class _StateDialog extends StatefulWidget {
  final String initial;
  final List<String> allStates;
  final ValueChanged<String> onSave;

  const _StateDialog({
    required this.initial,
    required this.allStates,
    required this.onSave,
  });

  @override
  State<_StateDialog> createState() => __StateDialogState();
}

class __StateDialogState extends State<_StateDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      backgroundColor: scheme.surface,
      title: Text(
        "Select State",
        style: TextStyle(color: scheme.onSurface),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView.builder(
            itemCount: widget.allStates.length,
            itemBuilder: (_, i) {
              return RadioListTile<String>(
                title: Text(
                  widget.allStates[i],
                  style: TextStyle(color: scheme.onSurface),
                ),
                value: widget.allStates[i],
                groupValue: _selected,
                activeColor: scheme.primary,
                onChanged: (v) {
                  setState(() => _selected = v!);
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
            widget.onSave(_selected);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}