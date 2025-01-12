import 'package:flutter/material.dart';
import '../models/predefined_fine.dart';

class SettingsFineList extends StatefulWidget {
  const SettingsFineList({super.key});

  @override
  State<SettingsFineList> createState() => _SettingsFineListState();
}

class _SettingsFineListState extends State<SettingsFineList> {
  List<PredefinedFine> fines = List.from(PredefinedFines.fines);

  void _addFine() {
    showDialog(
      context: context,
      builder: (context) => _FineDialog(
        onSave: (name, amount) {
          setState(() {
            fines.add(PredefinedFine(
              name: name,
              amount: amount,
            ));
          });
        },
      ),
    );
  }

  void _editFine(int index) {
    final fine = fines[index];
    showDialog(
      context: context,
      builder: (context) => _FineDialog(
        initialName: fine.name,
        initialAmount: fine.amount,
        onSave: (name, amount) {
          setState(() {
            fines[index] = PredefinedFine(
              name: name,
              amount: amount,
              isSpecial: fine.isSpecial,
              isCustomAmount: fine.isCustomAmount,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: fines.length,
        itemBuilder: (context, index) {
          final fine = fines[index];
          return ListTile(
            title: Text(fine.name),
            subtitle: Text('${fine.amount}€'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editFine(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFine,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FineDialog extends StatefulWidget {
  final String? initialName;
  final double? initialAmount;
  final Function(String name, double amount) onSave;

  const _FineDialog({
    this.initialName,
    this.initialAmount,
    required this.onSave,
  });

  @override
  State<_FineDialog> createState() => _FineDialogState();
}

class _FineDialogState extends State<_FineDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.initialName != null ? 'Strafe bearbeiten' : 'Neue Strafe'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Betrag (€)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text;
            final amount = double.tryParse(_amountController.text);
            if (name.isNotEmpty && amount != null) {
              widget.onSave(name, amount);
              Navigator.pop(context);
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
