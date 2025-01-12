import 'package:flutter/material.dart';
import '../models/predefined_fine.dart';

class ConfirmationDialog extends StatelessWidget {
  final String name;
  final PredefinedFine fine;

  const ConfirmationDialog({
    super.key,
    required this.name,
    required this.fine,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bestätigung'),
      content: Text(
        'Soll $name wirklich ${fine.amount}€ für "${fine.name}" zahlen?'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Bestätigen'),
        ),
      ],
    );
  }
}