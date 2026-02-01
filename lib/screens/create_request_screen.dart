// lib/screens/create_request_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/request_firestore_service.dart';
import '../utils/location_permission_utils.dart';
import '../widgets/map_location_picker.dart';

class CreateRequestScreen extends StatefulWidget {
  final Map<String, String>? mechanic;

  const CreateRequestScreen({super.key, this.mechanic});

  @override
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedVehicle = 'Car';
  final List<String> _attachedFiles = [];
  String? _detectedAddress;
  double? _userLat;
  double? _userLng;
  bool _locationDetected = false;
  bool _detecting = false;
  bool _submitting = false;

  Map<String, String>? _mechanic;
  final RequestFirestoreService _requestService = RequestFirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.mechanic != null) _mechanic = widget.mechanic;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mechanic == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, String>) _mechanic = args;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
                    'This is needed to attach photos to your request',
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
                    'Upload ID Document',
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
  // ATTACH FILE WITH PERMISSION & FILE PICKER
  // ------------------------------------------------
  Future<void> _attachFile() async {
    try {
      // Step 1: ALWAYS show permission bottom sheet first
      final permissionChoice = await _showPermissionBottomSheet();

      // User tapped "Don't allow" or dismissed
      if (permissionChoice == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot attach files.'),
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
              content: Text('Permission denied. Cannot attach files.'),
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
              content: Text('Permission permanently denied. Opening settings...'),
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
          _attachedFiles.add(result!.name);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Attached: ${result.name}')),
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

  /// Optionally convert lat/lng to a readable address using Geocoding API.
  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String>[
        if (p.street != null && p.street!.isNotEmpty) p.street!,
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
        if (p.postalCode != null && p.postalCode!.isNotEmpty) p.postalCode!,
        if (p.country != null && p.country!.isNotEmpty) p.country!,
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
      _detecting = true;
      _locationDetected = false;
      _detectedAddress = null;
      _userLat = null;
      _userLng = null;
    });

    final result = await requestLocationPermissionWithExplanation(context);
    if (!mounted) return;

    if (result != LocationPermissionResult.granted) {
      handlePermissionResult(context, result: result);
      setState(() => _detecting = false);
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      final lat = position.latitude;
      final lng = position.longitude;

      final confirmed = await Navigator.of(context).push<MapLocationResult>(
        MaterialPageRoute(
          builder: (ctx) => MapLocationPicker(
            initialLatitude: lat,
            initialLongitude: lng,
            onConfirm: (res) => Navigator.of(ctx).pop(res),
          ),
        ),
      );

      if (confirmed != null && mounted) {
        setState(() {
          _userLat = confirmed.latitude;
          _userLng = confirmed.longitude;
          _detectedAddress = confirmed.address;
          _locationDetected = true;
        });
        if (_detectedAddress == null || _detectedAddress!.isEmpty) {
          final address =
              await _reverseGeocode(confirmed.latitude, confirmed.longitude);
          if (mounted)
            setState(() => _detectedAddress = address ??
                '${confirmed.latitude.toStringAsFixed(5)}, ${confirmed.longitude.toStringAsFixed(5)}');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location confirmed.')));
        }
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location services are disabled. Please turn on GPS.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  void _removeAttached(String f) => setState(() => _attachedFiles.remove(f));

  Future<void> _onSubmit() async {
    final issueText = _descriptionController.text.trim();
    if (issueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please describe the issue.')));
      return;
    }
    if (!_locationDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please detect your location first.')));
      return;
    }

    setState(() => _submitting = true);

    try {
      // Extract mechanicId if mechanic is present
      String? mechanicId;
      if (_mechanic != null && _mechanic!['id'] != null) {
        mechanicId = _mechanic!['id'];
      }

      // Create request in Firestore (with lat/lng and optional address)
      final requestId = await _requestService.createRequest(
        vehicleType: _selectedVehicle,
        issue: issueText,
        location: _detectedAddress ?? '',
        mechanicId: mechanicId,
        images: _attachedFiles.isNotEmpty
            ? List<String>.from(_attachedFiles)
            : null,
        userLat: _userLat,
        userLng: _userLng,
        locationAddress: _detectedAddress,
      );

      // Clear form (optional)
      if (mounted) {
        setState(() {
          _descriptionController.clear();
          _attachedFiles.clear();
          _locationDetected = false;
          _detectedAddress = null;
          _userLat = null;
          _userLng = null;
        });
      }

      // Navigate to success screen, passing a small summary
      if (mounted) {
        Navigator.pushNamed(context, '/request_success', arguments: {
          'vehicle': _selectedVehicle,
          'summary': issueText,
          'requestId': requestId,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _mechanicHeader() {
    if (_mechanic == null) return const SizedBox.shrink();

    final name = _mechanic!['name'] ?? '';
    final shop = _mechanic!['shopName'] ?? '';
    final rating = _mechanic!['rating'] ?? '';
    final distance = _mechanic!['distanceKm'] ?? '';

    return Card(
      color: const Color(0xFF151515),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shop,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 6),
                Text(name, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(rating, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  const Icon(Icons.place, size: 14, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text('$distance km',
                      style: const TextStyle(color: Colors.white70)),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachedChips() {
    if (_attachedFiles.isEmpty) {
      return const Text('No photos attached',
          style: TextStyle(color: Colors.white70));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _attachedFiles.map((f) {
        return Chip(
          label: Text(f),
          backgroundColor: Colors.white10,
          labelStyle: const TextStyle(color: Colors.white),
          onDeleted: () => _removeAttached(f),
        );
      }).toList(),
    );
  }

  Widget _vehicleSelector() {
    final primary = Theme.of(context).colorScheme.primary;
    Widget btn(String type, IconData icon) {
      final selected = _selectedVehicle == type;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedVehicle = type),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: selected ? Colors.black : Colors.white),
              const SizedBox(height: 6),
              Text(type,
                  style: TextStyle(color: selected ? Colors.black : Colors.white)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      btn('Car', Icons.directions_car),
      btn('Motorcycle', Icons.motorcycle),
      btn('Truck', Icons.local_shipping),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Card(
              color: const Color(0xFF1A1A1A),
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mechanic != null) _mechanicHeader(),
                    const SizedBox(height: 4),
                    const Text('Request Details',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text(
                        'Provide details so a mechanic can assist you quickly.',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.local_taxi, color: Colors.yellow),
                      const SizedBox(width: 8),
                      const Text('Select Vehicle Type',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                    const SizedBox(height: 10),
                    _vehicleSelector(),
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.build, color: Colors.yellow),
                      const SizedBox(width: 8),
                      const Text('Describe the Issue',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText:
                            "Describe the problem (e.g., engine stalls when idling)...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      ElevatedButton.icon(
                        onPressed: _attachFile,
                        icon: const Icon(Icons.add_a_photo, color: Colors.black),
                        label: const Text('Attach Photo',
                            style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _attachedChips()),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Icon(Icons.place, color: Colors.yellow),
                      const SizedBox(width: 8),
                      const Text('Your Location',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _detecting ? null : _detectLocation,
                        icon: _detecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.my_location, color: Colors.black),
                        label: Text(
                            _detecting ? 'Detecting...' : 'Detect My Location',
                            style: const TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    if (_locationDetected) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.25))),
                        child: Text('Live location detected successfully!',
                            style: TextStyle(color: Colors.greenAccent.shade100)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.location_on, color: Colors.white70),
                            border: OutlineInputBorder(),
                            hintText: _detectedAddress,
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white12),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      const Text(
                          'Location not detected. Tap "Detect My Location" to set your location on the map.',
                          style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _onSubmit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.send, color: Colors.black),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Text(
                              _submitting ? 'Submitting...' : 'Submit Request',
                              style: const TextStyle(color: Colors.black)),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                        child: Text(
                            'Tip: Provide clear description and photos for faster help.',
                            style: TextStyle(color: Colors.white70))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Cancel')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}