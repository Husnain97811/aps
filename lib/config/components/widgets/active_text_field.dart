// active_text_field.dart
import 'package:flutter/material.dart';
import 'package:aps/services/session_service.dart';

class ActiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  const ActiveTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => SessionService.resetInactivityTimer(),
      onTap: () => SessionService.resetInactivityTimer(),
    );
  }
}
