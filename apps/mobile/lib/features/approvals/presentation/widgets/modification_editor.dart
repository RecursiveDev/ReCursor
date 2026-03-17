import 'package:flutter/material.dart';

/// A labeled text field + submit button used on the approval detail screen
/// when the user chooses to modify a tool call.
class ModificationEditor extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const ModificationEditor({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Modifications',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Describe your modifications…',
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Modifications'),
        ),
      ],
    );
  }
}
