import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MechanicRegisterScreen extends StatefulWidget {
  const MechanicRegisterScreen({super.key});

  @override
  State<MechanicRegisterScreen> createState() => _MechanicRegisterScreenState();
}

class _MechanicRegisterScreenState extends State<MechanicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Required
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _vehicleTypes = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  // Additional
  final _personalAddress = TextEditingController();
  final _shopAddress = TextEditingController();
  final _yearsExp = TextEditingController();
  final _idNumber = TextEditingController();

  final AuthService _auth = AuthService();

  bool _loading = false;
  bool _hidePassword = true;

  String _selectedIdType = 'DL';
  String? _pickedIdFileName;

  @override
  void dispose() {
    for (final c in [
      _name,
      _shop,
      _vehicleTypes,
      _email,
      _phone,
      _password,
      _personalAddress,
      _shopAddress,
      _yearsExp,
      _idNumber,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // =========================================================
  // VALIDATORS
  // =========================================================
  String? _req(String? v, String field) {
    if (v == null || v.trim().isEmpty) return 'Enter $field';
    return null;
  }

  String? _emailV(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) return 'Enter valid email';
    return null;
  }

  String? _phoneV(String? v) {
    final value = (v ?? '').trim();
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) return 'Enter 10-digit phone number';
    return null;
  }

  String? _passwordV(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // =========================================================
  // FILE PICKER (Mock)
  // =========================================================
  Future<void> _pickIdFile() async {
    final f = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Choose ID file'),
        children: [
          SimpleDialogOption(
            child: const Text('id_front.jpg'),
            onPressed: () => Navigator.pop(c, 'id_front.jpg'),
          ),
          SimpleDialogOption(
            child: const Text('id_back.jpg'),
            onPressed: () => Navigator.pop(c, 'id_back.jpg'),
          ),
        ],
      ),
    );

    if (f != null && mounted) {
      setState(() => _pickedIdFileName = f);
    }
  }

  // =========================================================
  // REGISTER
  // =========================================================
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _auth.registerMechanic(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text.trim(),
        address: _shopAddress.text.trim().isEmpty
            ? _personalAddress.text.trim()
            : _shopAddress.text.trim(),
        shopName: _shop.text.trim(),
        vehicleTypes: _vehicleTypes.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully ✅')),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      );

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register - Mechanic')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Create Mechanic Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ✅ REQUIRED DETAILS
              TextFormField(
                controller: _name,
                decoration: _dec('Full name', Icons.person),
                validator: (v) => _req(v, 'full name'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _shop,
                decoration: _dec('Shop / Garage name', Icons.store),
                validator: (v) => _req(v, 'shop name'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _vehicleTypes,
                decoration: _dec(
                  'Vehicle types serviced (Bike, Car, Truck...)',
                  Icons.directions_car,
                ),
                validator: (v) => _req(v, 'vehicle types'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _email,
                decoration: _dec('Email', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: _emailV,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phone,
                decoration: _dec('Phone', Icons.phone),
                keyboardType: TextInputType.phone,
                validator: _phoneV,
              ),
              const SizedBox(height: 12),

              // ✅ PASSWORD
              TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: _passwordV,
              ),
              const SizedBox(height: 12),

              // ✅ ADDITIONAL DETAILS
              ExpansionTile(
                title: const Text('Additional Details (Optional)'),
                children: [
                  TextFormField(
                    controller: _personalAddress,
                    decoration: _dec('Personal address', Icons.home),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _shopAddress,
                    decoration: _dec('Shop address', Icons.location_on),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _yearsExp,
                    decoration: _dec('Years of experience', Icons.timer),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedIdType,
                          items: const [
                            DropdownMenuItem(value: 'DL', child: Text('DL')),
                            DropdownMenuItem(
                              value: 'Aadhaar',
                              child: Text('Aadhaar'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedIdType = v ?? 'DL'),
                          decoration: _dec('ID Type', Icons.badge),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _idNumber,
                          decoration: _dec('ID Number', Icons.numbers),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: _pickIdFile,
                    icon: const Icon(Icons.upload),
                    label: Text(_pickedIdFileName ?? 'Choose ID File'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),

              const SizedBox(height: 16),

              // ✅ SUBMIT
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Register as Mechanic'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
