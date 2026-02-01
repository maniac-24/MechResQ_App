import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/auth_service.dart';
import 'shop_location_picker_screen.dart';

class MechanicRegisterScreen extends StatefulWidget {
  const MechanicRegisterScreen({super.key});

  @override
  State<MechanicRegisterScreen> createState() =>
      _MechanicRegisterScreenState();
}

class _MechanicRegisterScreenState extends State<MechanicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // REQUIRED
  final _name = TextEditingController();
  final _shop = TextEditingController();
  final _vehicleTypes = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  // OPTIONAL
  final _personalAddress = TextEditingController();
  final _shopAddress = TextEditingController();
  final _yearsExp = TextEditingController();
  final _idNumber = TextEditingController();

  final AuthService _auth = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _hidePassword = true;

  String _selectedIdType = 'DL';

  File? _pickedIdFile;
  String? _pickedIdFileName;

  ShopLocationResult? _shopLocation;

  // ------------------------------------------------
  // VALIDATORS
  // ------------------------------------------------
  String? _req(String? v, String name) =>
      (v == null || v.trim().isEmpty) ? 'Enter $name' : null;

  String? _emailV(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter valid email';
    }
    return null;
  }

  String? _phoneV(String? v) {
    if (!RegExp(r'^\d{10}$').hasMatch(v ?? '')) {
      return 'Enter 10-digit phone number';
    }
    return null;
  }

  String? _passwordV(String? v) {
    if (v == null || v.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ------------------------------------------------
  // ENABLE REGISTER?
  // ------------------------------------------------
  bool get _canRegister {
    return !_loading &&
        _shopLocation != null &&
        _pickedIdFile != null &&
        _formKey.currentState?.validate() == true;
  }

  // ------------------------------------------------
  // ANDROID-STYLE PERMISSION BOTTOM SHEET
  // ------------------------------------------------
  Future<String?> _showPermissionBottomSheet() async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: const Text(
                      'MechResQ wants to access your storage',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: const Text(
                      'This is needed to upload your ID documents',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12, height: 1),
                  _permissionOption(context,
                      title: 'While using the app', value: 'while_using'),
                  const Divider(color: Colors.white12, height: 1),
                  _permissionOption(context,
                      title: 'Only this time', value: 'only_this_time'),
                  const Divider(color: Colors.white12, height: 1),
                  _permissionOption(
                      context, title: "Don't allow", value: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _permissionOption(BuildContext context,
      {required String title, required String? value}) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF6C9FFF),
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ------------------------------------------------
  // FILE PICKER BOTTOM SHEET
  // ------------------------------------------------
  Future<String?> _showFilePickerBottomSheet() async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: const Text(
                      'Upload ID Document',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12, height: 1),
                  _fileOption(context,
                      icon: Icons.camera_alt,
                      title: 'Take Photo',
                      value: 'camera'),
                  const Divider(color: Colors.white12, height: 1),
                  _fileOption(context,
                      icon: Icons.photo_library,
                      title: 'Choose from Gallery',
                      value: 'gallery'),
                  const Divider(color: Colors.white12, height: 1),
                  _fileOption(context,
                      icon: Icons.insert_drive_file,
                      title: 'Choose PDF / File',
                      value: 'file'),
                  const Divider(color: Colors.white12, height: 1),
                  _fileOption(
                      context, icon: Icons.close, title: 'Cancel', value: null),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fileOption(BuildContext context,
      {required IconData icon, required String title, required String? value}) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C9FFF), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6C9FFF),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // MAIN FILE PICKER LOGIC (REORDERED - PERMISSION FIRST)
  // ------------------------------------------------
  Future<void> _pickIdFile() async {
    try {
      // Step 1: ALWAYS show permission bottom sheet first
      final permissionChoice = await _showPermissionBottomSheet();

      // User tapped "Don't allow" or dismissed
      if (permissionChoice == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot upload files.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 2: Check and request actual system permission based on Android version
      PermissionStatus permissionStatus;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          permissionStatus = await Permission.photos.status;
        } else {
          permissionStatus = await Permission.storage.status;
        }
      } else {
        permissionStatus = await Permission.storage.status;
      }

      // Request permission if not granted
      if (!permissionStatus.isGranted) {
        PermissionStatus newPermission;
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          if (androidInfo.version.sdkInt >= 33) {
            newPermission = await Permission.photos.request();
          } else {
            newPermission = await Permission.storage.request();
          }
        } else {
          newPermission = await Permission.storage.request();
        }

        // Handle system permission denial
        if (newPermission.isDenied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied. Cannot upload files.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Handle permanently denied → redirect to settings
        if (newPermission.isPermanentlyDenied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Permission permanently denied. Opening settings...'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          await openAppSettings();
          return;
        }
      }

      // Step 3: Permission granted → show file picker options
      if (!mounted) return;
      final fileChoice = await _showFilePickerBottomSheet();
      if (fileChoice == null) return;

      XFile? result;

      if (fileChoice == 'camera') {
        // Request camera permission separately
        final cameraPermission = await Permission.camera.request();
        if (!cameraPermission.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        result = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
      } else if (fileChoice == 'gallery') {
        result = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
      } else if (fileChoice == 'file') {
        result = await openFile(
          acceptedTypeGroups: [
            XTypeGroup(
              label: 'Documents',
              extensions: ['pdf', 'jpg', 'jpeg', 'png'],
            ),
          ],
        );
      }

      // Step 4: File selected successfully
      if (result != null && result.path.isNotEmpty) {
        setState(() {
          _pickedIdFile = File(result!.path);
          _pickedIdFileName = result.name;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('${result.name} uploaded')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ------------------------------------------------
  // LOCATION
  // ------------------------------------------------
  Future<void> _openSetWorkshopLocation() async {
    final result = await Navigator.push<ShopLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => ShopLocationPickerScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() => _shopLocation = result);
    }
  }

  // ------------------------------------------------
  // REGISTER
  // ------------------------------------------------
  Future<void> _register() async {
    if (!_canRegister) return;

    setState(() => _loading = true);

    try {
      await _auth.registerMechanic(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text.trim(),
        shopName: _shop.text.trim(),
        vehicleTypes: _vehicleTypes.text.trim(),
        address: _shopAddress.text.trim().isEmpty
            ? _personalAddress.text.trim()
            : _shopAddress.text.trim(),
        shopLat: _shopLocation!.latitude,
        shopLng: _shopLocation!.longitude,
        shopAddress: _shopLocation!.shopAddress,
        idType: _selectedIdType,
        idNumber: _idNumber.text.trim(),
        idFileName: _pickedIdFileName!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registered successfully ✅')),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register - Mechanic')),
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
                decoration:
                    _dec('Vehicle types serviced', Icons.directions_car),
                validator: (v) => _req(v, 'vehicle types'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _email,
                decoration: _dec('Email', Icons.email),
                validator: _emailV,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phone,
                decoration: _dec('Phone', Icons.phone),
                validator: _phoneV,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                  ),
                ),
                validator: _passwordV,
              ),

              const SizedBox(height: 24),

              const Text(
                'Additional Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

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

              TextFormField(
                controller: _idNumber,
                decoration: _dec('ID Number', Icons.badge),
              ),
              const SizedBox(height: 10),

              // ID FILE PICKER BUTTON
              ElevatedButton.icon(
                onPressed: _pickIdFile,
                icon: const Icon(Icons.upload),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: Text(
                  _pickedIdFileName ?? 'Choose ID File',
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              // File confirmation box
              if (_pickedIdFile != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File selected: $_pickedIdFileName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Set Workshop Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              OutlinedButton.icon(
                onPressed: _openSetWorkshopLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(
                  _shopLocation == null
                      ? Icons.location_on
                      : Icons.check_circle,
                  color: _shopLocation == null ? null : Colors.green,
                ),
                label: Text(
                  _shopLocation == null
                      ? 'Set Workshop Location'
                      : 'Workshop location set',
                  style: TextStyle(
                    color: _shopLocation == null ? null : Colors.green,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // REGISTER BUTTON
              ElevatedButton(
                onPressed: _canRegister ? _register : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canRegister ? null : Colors.grey,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          _canRegister
                              ? 'Register as Mechanic'
                              : 'Complete all required fields',
                        ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _shop.dispose();
    _vehicleTypes.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _personalAddress.dispose();
    _shopAddress.dispose();
    _yearsExp.dispose();
    _idNumber.dispose();
    super.dispose();
  }
}