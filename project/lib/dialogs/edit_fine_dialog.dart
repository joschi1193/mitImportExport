import 'package:flutter/material.dart';
import '../models/predefined_fine.dart';

class EditFineDialog extends StatefulWidget {
  final PredefinedFine? fine;

  const EditFineDialog({
    super.key,
    this.fine,
  });

  @override
  State<EditFineDialog> createState() => _EditFineDialogState();
}

class _EditFineDialogState extends State<EditFineDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  bool _isSpecial = false;
  bool _isCustomAmount = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fine?.name);
    _amountController = TextEditingController(
      text: widget.fine?.amount.toStringAsFixed(2),
    );
    _isSpecial = widget.fine?.isSpecial ?? false;
    _isCustomAmount = widget.fine?.isCustomAmount ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.fine == null ? 'Neue Strafe' : 'Strafe bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Betrag (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Alle anderen müssen zahlen!'),
              value: _isSpecial,
              onChanged: (value) {
                setState(() {
                  _isSpecial = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Benutzerdefinierter Betrag'),
              value: _isCustomAmount,
              onChanged: (value) {
                setState(() {
                  _isCustomAmount = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0.0;
            final fine = PredefinedFine(
              name: _nameController.text,
              amount: amount,
              isSpecial: _isSpecial,
              isCustomAmount: _isCustomAmount,
            );
            Navigator.pop(context, fine);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
