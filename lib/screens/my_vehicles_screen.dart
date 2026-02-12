import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../utils/snackbar_helper.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameC = TextEditingController();
  final _makeC = TextEditingController();
  final _modelC = TextEditingController();
  final _yearC = TextEditingController();
  final _plateC = TextEditingController();

  String? _vehicleType;
  File? _image;
  String? _imageName;

  final _vehicleTypes = ['Car', 'Bike', 'Truck', 'Other'];

  @override
  void dispose() {
    _nameC.dispose();
    _makeC.dispose();
    _modelC.dispose();
    _yearC.dispose();
    _plateC.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // PERMISSION EXPLANATION (only WHY, not HOW)
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
                'We need access to your photos to upload vehicle images.',
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
                  'Upload Vehicle Image',
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
              _fileOption(context,
                  icon: Icons.close, title: 'Cancel', value: null),
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
  // ✅ CORRECTED PERMISSION FLOW
  // ------------------------------------------------
  Future<void> _chooseImage() async {
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
            'Permission needed to upload images.',
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
            'Permission denied. Cannot upload images.',
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
              label: 'Images',
              extensions: ['jpg', 'jpeg', 'png'],
            ),
          ],
        );
      }

      // File selected successfully
      if (result != null && result.path.isNotEmpty) {
        setState(() {
          _image = File(result!.path);
          _imageName = result.name;
        });

        if (!mounted) return;
        SnackBarHelper.showSuccess(
          context,
          'Image selected: ${result.name}',
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    SnackBarHelper.showSuccess(
      context,
      'Vehicle added successfully ✅',
    );

    _formKey.currentState!.reset();
    setState(() {
      _vehicleType = null;
      _image = null;
      _imageName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _input(_nameC, 'Vehicle Name'),
            const SizedBox(height: 14),
            _dropdown(
              label: 'Vehicle Type',
              value: _vehicleType,
              items: _vehicleTypes,
              onChanged: (v) => setState(() => _vehicleType = v),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _input(_makeC, 'Make')),
                const SizedBox(width: 12),
                Expanded(child: _input(_modelC, 'Model')),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _input(
                    _yearC,
                    'Year (e.g., 2020)',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _input(_plateC, 'License Plate')),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(6),
                    color: scheme.surfaceContainerHigh,
                  ),
                  child: _image == null
                      ? Center(
                          child: Text(
                            'No image',
                            style: TextStyle(
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  onPressed: _chooseImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Choose Image'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _formKey.currentState!.reset();
                      setState(() {
                        _vehicleType = null;
                        _image = null;
                        _imageName = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Add Vehicle',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}