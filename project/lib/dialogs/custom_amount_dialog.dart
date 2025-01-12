import 'package:flutter/material.dart';

class CustomAmountDialog extends StatelessWidget {
  final String name;
  final String fineName;

  const CustomAmountDialog({
    super.key,
    required this.name,
    required this.fineName,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return AlertDialog(
      title: Text('Strafbetrag für $name'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Betrag (€)',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(controller.text);
            if (amount != null && amount > 0) {
              Navigator.pop(context, amount);
            }
          },
          child: const Text('Bestätigen'),
        ),
      ],
    );
  }
}