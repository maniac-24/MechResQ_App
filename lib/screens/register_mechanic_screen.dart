import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
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

  // SERVICES OFFERED STATE
  static const List<String> _predefinedServices = [
    'Engine Repair & Servicing',
    'Battery & Electrical',
    'Tyre Change & Puncture',
    'Oil & Fluid Change',
    'General Maintenance',
  ];

  List<String> _allServices = List.from(_predefinedServices);
  List<String> _selectedServices = [];
  String? _servicesError;

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
  // VALIDATE SERVICES
  // ------------------------------------------------
  bool _validateServices() {
    if (_selectedServices.isEmpty) {
      setState(() => _servicesError = 'Select at least one service');
      return false;
    }
    setState(() => _servicesError = null);
    return true;
  }

  // ------------------------------------------------
  // ENABLE REGISTER?
  // ------------------------------------------------
  bool get _canRegister {
    return !_loading &&
        _shopLocation != null &&
        _pickedIdFile != null &&
        _selectedServices.isNotEmpty &&
        _formKey.currentState?.validate() == true;
  }

  // ------------------------------------------------
  // SERVICES CHIP LOGIC
  // ------------------------------------------------
  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
      _servicesError = null;
    });
  }

  // ------------------------------------------------
  // ADD CUSTOM SERVICE DIALOG
  // ------------------------------------------------
  Future<void> _showAddServiceDialog() async {
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Add Custom Service',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: scheme.onSurface),
          decoration: InputDecoration(
            hintText: 'e.g., AC Repair',
            hintStyle: TextStyle(
              color: scheme.onSurface.withOpacity(0.5),
            ),
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            onPressed: () {
              final serviceName = controller.text.trim();
              if (serviceName.isNotEmpty) {
                Navigator.pop(context, serviceName);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_allServices.contains(result)) {
          _allServices.add(result);
        }
        if (!_selectedServices.contains(result)) {
          _selectedServices.add(result);
        }
        _servicesError = null;
      });
    }
  }

  // ------------------------------------------------
  // PERMISSION EXPLANATION
  // ------------------------------------------------
  Future<bool?> _showPermissionExplanation() async {
    final scheme = Theme.of(context).colorScheme;
    
    return await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Storage Access Needed',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We need access to upload your ID documents.',
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // FILE PICKER BOTTOM SHEET
  // ------------------------------------------------
  Future<String?> _showFilePickerBottomSheet() async {
    final scheme = Theme.of(context).colorScheme;
    
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Upload ID Document',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(context,
                  icon: Icons.camera_alt,
                  title: 'Take Photo',
                  value: 'camera'),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(context,
                  icon: Icons.photo_library,
                  title: 'Choose from Gallery',
                  value: 'gallery'),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(context,
                  icon: Icons.insert_drive_file,
                  title: 'Choose PDF / File',
                  value: 'file'),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(
                  context, icon: Icons.close, title: 'Cancel', value: null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileOption(BuildContext context,
      {required IconData icon, required String title, required String? value}) {
    final scheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: scheme.primary,
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
  // PERMISSION FLOW
  // ------------------------------------------------
  Future<void> _pickIdFile() async {
    try {
      // Check permission status FIRST
      PermissionStatus storageStatus;
      if (Platform.isAndroid) {
        final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        storageStatus = sdk >= 33
            ? await Permission.photos.status
            : await Permission.storage.status;
      } else {
        storageStatus = await Permission.storage.status;
      }

      // ONLY show explanation if permission is NOT granted
      if (!storageStatus.isGranted) {
        if (!mounted) return;
        final userWantsToContinue = await _showPermissionExplanation();

        if (userWantsToContinue != true) {
          if (!mounted) return;
          SnackBarHelper.showWarning(
            context,
            'Permission needed to upload files.',
          );
          return;
        }

        // Now request actual system permission
        PermissionStatus newPermission;
        if (Platform.isAndroid) {
          final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
          newPermission = sdk >= 33
              ? await Permission.photos.request()
              : await Permission.storage.request();
        } else {
          newPermission = await Permission.storage.request();
        }

        // Handle denial
        if (newPermission.isDenied) {
          if (!mounted) return;
          SnackBarHelper.showError(
            context,
            'Permission denied. Cannot upload files.',
          );
          return;
        }

        // Handle permanently denied
        if (newPermission.isPermanentlyDenied) {
          if (!mounted) return;
          SnackBarHelper.showWarning(
            context,
            'Permission permanently denied. Opening settings...',
          );
          await Future.delayed(const Duration(seconds: 2));
          await openAppSettings();
          return;
        }
      }

      // Permission is now granted → show file picker
      if (!mounted) return;
      final fileChoice = await _showFilePickerBottomSheet();
      if (fileChoice == null) return;

      XFile? result;

      if (fileChoice == 'camera') {
        // Check camera status FIRST
        final cameraStatus = await Permission.camera.status;

        if (!cameraStatus.isGranted) {
          final cameraPermission = await Permission.camera.request();
          if (!cameraPermission.isGranted) {
            if (!mounted) return;
            SnackBarHelper.showError(
              context,
              'Camera permission required',
            );
            return;
          }
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

      // File selected successfully
      if (result != null && result.path.isNotEmpty) {
        setState(() {
          _pickedIdFile = File(result!.path);
          _pickedIdFileName = result.name;
        });

        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          '${result.name} uploaded',
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'Error: ${e.toString()}',
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
    if (!_validateServices()) {
      SnackBarHelper.showError(
        context,
        'Please select at least one service',
      );
      return;
    }

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
        services: _selectedServices,
      );

      if (!mounted) return;

      SnackBarHelper.showSuccess(
        context,
        'Registered successfully ✅',
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        e.toString(),
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
  // BUILD SERVICES CHIPS UI
  // ------------------------------------------------
  Widget _buildServicesSection() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services Offered *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        if (_servicesError != null) ...[
          const SizedBox(height: 4),
          Text(
            _servicesError!,
            style: TextStyle(color: scheme.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Service chips
            ..._allServices.map((service) {
              final isSelected = _selectedServices.contains(service);
              return FilterChip(
                label: Text(service),
                selected: isSelected,
                onSelected: (_) => _toggleService(service),
                backgroundColor: scheme.surfaceContainerHigh,
                selectedColor: scheme.primaryContainer,
                checkmarkColor: scheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                    width: 1,
                  ),
                ),
              );
            }),

            // Add service chip
            ActionChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Add Service',
                    style: TextStyle(color: scheme.primary),
                  ),
                ],
              ),
              onPressed: _showAddServiceDialog,
              backgroundColor: scheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: scheme.primary, width: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedServices.length} service(s) selected',
          style: TextStyle(
            fontSize: 12,
            color: _selectedServices.isEmpty
                ? scheme.error
                : scheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Register - Mechanic')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Create Mechanic Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
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

              // SERVICES OFFERED SECTION
              _buildServicesSection(),

              const SizedBox(height: 24),

              Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
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
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.secondary),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File selected: $_pickedIdFileName',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                'Set Workshop Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
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
                  color: _shopLocation == null
                      ? null
                      : scheme.secondary,
                ),
                label: Text(
                  _shopLocation == null
                      ? 'Set Workshop Location'
                      : 'Workshop location set',
                  style: TextStyle(
                    color: _shopLocation == null
                        ? null
                        : scheme.secondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // REGISTER BUTTON
              ElevatedButton(
                onPressed: _canRegister ? _register : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
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