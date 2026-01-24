// lib/widgets/input_field.dart
import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final IconData? icon;

  const InputField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.validator,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator ?? _defaultValidator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(),
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $label';
    }
    return null;
  }
}
