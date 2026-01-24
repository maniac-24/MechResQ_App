import 'dart:io';
import 'package:flutter/material.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameC = TextEditingController();
  final _makeC = TextEditingController();
  final _modelC = TextEditingController();
  final _yearC = TextEditingController();
  final _plateC = TextEditingController();

  String? _vehicleType;
  File? _image;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle added (demo)')),
    );

    _formKey.currentState!.reset();
    setState(() {
      _vehicleType = null;
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
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
                    ),
                    child: Center(
                      child: Text(
                        _image == null ? 'No image' : 'Image',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image picker will be added later'),
                        ),
                      );
                    },
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
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
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
      initialValue: value,
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
