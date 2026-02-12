import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({Key? key}) : super(key: key);

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Required
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  // Optional
  final _address = TextEditingController();
  final _idNumber = TextEditingController();

  final AuthService _auth = AuthService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  bool _hidePassword = true;

  String _selectedIdType = 'Aadhaar';
  File? _pickedIdFile;
  String? _pickedIdFileName;

  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_validateForm);
    _email.addListener(_validateForm);
    _phone.addListener(_validateForm);
    _password.addListener(_validateForm);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _address.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  void _validateForm() {
    final nameValid = _name.text.trim().isNotEmpty;
    final emailValid = _email.text.trim().isNotEmpty &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
    final phoneValid = RegExp(r'^\d{10}$').hasMatch(_phone.text.trim());
    final passwordValid = _password.text.trim().length >= 6;

    final isValid = nameValid && emailValid && phoneValid && passwordValid;

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  // ---------------- VALIDATORS ----------------
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter full name';
    return null;
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter valid email';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    final value = (v ?? '').trim();
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter 10-digit phone number';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ---------------- PERMISSION EXPLANATION ----------------
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

  // ---------------- FILE PICKER BOTTOM SHEET ----------------
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
              _fileOption(
                context,
                icon: Icons.camera_alt,
                title: 'Take Photo',
                value: 'camera',
              ),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(
                context,
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                value: 'gallery',
              ),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(
                context,
                icon: Icons.insert_drive_file,
                title: 'Choose PDF / File',
                value: 'file',
              ),
              Divider(color: scheme.outlineVariant, height: 1),
              _fileOption(
                context,
                icon: Icons.close,
                title: 'Cancel',
                value: null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String? value,
  }) {
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

  // ---------------- PERMISSION FLOW ----------------
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

  // ---------------- REGISTER ----------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _auth.registerUser(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text.trim(),
      );

      if (!mounted) return;

      SnackBarHelper.showSuccess(
        context,
        'Registration successful ✅ Please login.',
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Register - User'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Create User Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // NAME
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Full name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),

                  // EMAIL
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),

                  // PHONE
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 12),

                  // PASSWORD
                  TextFormField(
                    controller: _password,
                    obscureText: _hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 12),

                  // ADDRESS (optional)
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(
                      labelText: 'Address (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // ID PROOF (optional)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedIdType,
                          items: const [
                            DropdownMenuItem(
                              value: 'Aadhaar',
                              child: Text('Aadhaar'),
                            ),
                            DropdownMenuItem(
                              value: 'Driving License',
                              child: Text('Driving License'),
                            ),
                            DropdownMenuItem(
                              value: 'Passport',
                              child: Text('Passport'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedIdType = v ?? 'Aadhaar'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _idNumber,
                          decoration: const InputDecoration(
                            labelText: 'ID Proof Number (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.confirmation_number),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // FILE PICK BUTTON
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickIdFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedIdFileName ?? 'No file chosen',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _pickedIdFileName != null
                                ? scheme.secondary
                                : scheme.onSurface.withOpacity(0.5),
                            fontWeight: _pickedIdFileName != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
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
                              'File uploaded: $_pickedIdFileName',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // REGISTER BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_loading || !_isFormValid) ? null : _register,
                      child: _loading
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                _isFormValid
                                    ? 'Register'
                                    : 'Fill all required fields (*)',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}