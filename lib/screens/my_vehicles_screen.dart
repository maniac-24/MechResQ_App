import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  // PERMISSION BOTTOM SHEET
  // ------------------------------------------------
  Future<String?> _showPermissionBottomSheet() async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
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
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: const Text(
                    'This is needed to upload vehicle images',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
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
                _permissionOption(context, title: "Don't allow", value: null),
              ],
            ),
          ),
        ),
      ),
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
      builder: (context) => Container(
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
                    'Upload Vehicle Image',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600),
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
                _fileOption(context,
                    icon: Icons.close, title: 'Cancel', value: null),
              ],
            ),
          ),
        ),
      ),
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
  // CHOOSE IMAGE WITH PERMISSION FLOW
  // ------------------------------------------------
  Future<void> _chooseImage() async {
    try {
      // Step 1: ALWAYS show permission bottom sheet first
      final permissionChoice = await _showPermissionBottomSheet();

      // User tapped "Don't allow" or dismissed
      if (permissionChoice == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot upload images.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Step 2: Check and request actual system permission
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
              content: Text('Permission denied. Cannot upload images.'),
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
              label: 'Images',
              extensions: ['jpg', 'jpeg', 'png'],
            ),
          ],
        );
      }

      // Step 4: File selected successfully
      if (result != null && result.path.isNotEmpty) {
        setState(() {
          _image = File(result!.path);
          _imageName = result.name;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Image selected: ${result.name}')),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle added successfully ✅')),
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
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // ✅ ONLY "My Vehicles" - no menu, no actions
      appBar: AppBar(
        title: const Text('My Vehicles'),
        centerTitle: true,
        automaticallyImplyLeading: false, // ✅ Removes menu/back button
        actions: const [], // ✅ No actions
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Name
              _input(_nameC, 'Vehicle Name'),
              const SizedBox(height: 14),

              // Vehicle Type
              _dropdown(
                label: 'Vehicle Type',
                value: _vehicleType,
                items: _vehicleTypes,
                onChanged: (v) => setState(() => _vehicleType = v),
              ),
              const SizedBox(height: 14),

              // Make | Model
              Row(
                children: [
                  Expanded(child: _input(_makeC, 'Make')),
                  const SizedBox(width: 12),
                  Expanded(child: _input(_modelC, 'Model')),
                ],
              ),
              const SizedBox(height: 14),

              // Year | License Plate
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

              // Image picker row
              Row(
                children: [
                  Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white10,
                    ),
                    child: _image == null
                        ? const Center(
                            child: Text(
                              'No image',
                              style: TextStyle(color: Colors.white70),
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
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _chooseImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Choose Image'),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Buttons
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
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
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
      ),
      // ✅ NO FloatingActionButton (+ button removed)
    );
  }

  // ---------------- HELPERS ----------------

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