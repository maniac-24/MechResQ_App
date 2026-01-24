// lib/screens/create_request_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/request_firestore_service.dart';

/// CreateRequestScreen
// ignore: unintended_html_in_doc_comment
/// - Accepts mechanic Map<String,String> either via constructor or via
///   Navigator arguments: Navigator.pushNamed(context,'/create_request', arguments: mechanicMap)
/// - On submit it saves the request via RequestService.add(...) and navigates to '/request_success'.
class CreateRequestScreen extends StatefulWidget {
  final Map<String, String>? mechanic;

  const CreateRequestScreen({super.key, this.mechanic});

  @override
  // ignore: library_private_types_in_public_api
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _descriptionController = TextEditingController();
  String _selectedVehicle = 'Car';
  final List<String> _attachedFiles = [];
  String? _detectedAddress;
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

  Future<void> _simulateAttachFile() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Attach photo (simulated)'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'photo_front.jpg'), child: const Text('photo_front.jpg')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'photo_closeup.jpg'), child: const Text('photo_closeup.jpg')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (chosen != null) {
      setState(() => _attachedFiles.add(chosen));
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attached: $chosen')));
    }
  }

  Future<void> _simulateDetectLocation() async {
    setState(() {
      _detecting = true;
      _locationDetected = false;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _locationDetected = true;
      _detectedAddress = '8M92+749, Nannivala Rd, Rahim Nagar, Challakere, Karnataka 577522, India';
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live location detected successfully!')));
  }

  void _removeAttached(String f) => setState(() => _attachedFiles.remove(f));

  Future<void> _onSubmit() async {
    final issueText = _descriptionController.text.trim();
    if (issueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the issue.')));
      return;
    }
    if (!_locationDetected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please detect your location first.')));
      return;
    }

    setState(() => _submitting = true);

    try {
      // Extract mechanicId if mechanic is present
      String? mechanicId;
      if (_mechanic != null && _mechanic!['id'] != null) {
        mechanicId = _mechanic!['id'];
      }

      // Create request in Firestore
      final requestId = await _requestService.createRequest(
        vehicleType: _selectedVehicle,
        issue: issueText,
        location: _detectedAddress ?? '',
        mechanicId: mechanicId,
        images: _attachedFiles.isNotEmpty ? List<String>.from(_attachedFiles) : null,
      );

      // Clear form (optional)
      if (mounted) {
        setState(() {
          _descriptionController.clear();
          _attachedFiles.clear();
          _locationDetected = false;
          _detectedAddress = null;
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
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'M', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(shop, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
                  Text('$distance km', style: const TextStyle(color: Colors.white70)),
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
      return const Text('No photos attached', style: TextStyle(color: Colors.white70));
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
              Text(type, style: TextStyle(color: selected ? Colors.black : Colors.white)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mechanic != null) _mechanicHeader(),

                    const SizedBox(height: 4),
                    const Text('Request Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    const Text('Provide details so a mechanic can assist you quickly.', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),

                    Row(children: [
                      const Icon(Icons.local_taxi, color: Colors.yellow),
                      const SizedBox(width: 8),
                      const Text('Select Vehicle Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                    const SizedBox(height: 10),
                    _vehicleSelector(),
                    const SizedBox(height: 14),

                    Row(children: [
                      const Icon(Icons.build, color: Colors.yellow),
                      const SizedBox(width: 8),
                      const Text('Describe the Issue', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Describe the problem (e.g., engine stalls when idling)...",
                        hintStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(children: [
                      ElevatedButton.icon(
                        onPressed: _simulateAttachFile,
                        icon: const Icon(Icons.add_a_photo, color: Colors.black),
                        label: const Text('Attach Photo', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _attachedChips()),
                    ]),
                    const SizedBox(height: 16),

                    Row(children: [
                      const Icon(Icons.place, color: Colors.yellow),
                      const SizedBox(width: 8),
                      const Text('Your Location', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _detecting ? null : _simulateDetectLocation,
                        icon: const Icon(Icons.my_location, color: Colors.black),
                        label: Text(_detecting ? 'Detecting...' : 'Detect Location', style: const TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    if (_locationDetected) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.25))),
                        child: Text('Live location detected successfully!', style: TextStyle(color: Colors.greenAccent.shade100)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        readOnly: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.location_on, color: Colors.white70), border: OutlineInputBorder(), hintText: _detectedAddress, hintStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: Colors.white12),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      const Text('Location not detected. Tap "Detect Location" to detect.', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _onSubmit,
                        icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.send, color: Colors.black),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Text(_submitting ? 'Submitting...' : 'Submit Request', style: const TextStyle(color: Colors.black)),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Center(child: Text('Tip: Provide clear description and photos for faster help.', style: TextStyle(color: Colors.white70))),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text('Cancel')),
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
