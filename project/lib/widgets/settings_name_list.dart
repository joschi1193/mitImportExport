import 'package:flutter/material.dart';
import '../models/predefined_names.dart';

class SettingsNameList extends StatefulWidget {
  const SettingsNameList({super.key});

  @override
  State<SettingsNameList> createState() => _SettingsNameListState();
}

class _SettingsNameListState extends State<SettingsNameList> {
  List<String> names = List.from(PredefinedNames.names);

  void _addName() {
    showDialog(
      context: context,
      builder: (context) => _NameDialog(
        onSave: (name) {
          setState(() {
            names.add(name);
          });
        },
      ),
    );
  }

  void _editName(int index) {
    showDialog(
      context: context,
      builder: (context) => _NameDialog(
        initialName: names[index],
        onSave: (name) {
          setState(() {
            names[index] = name;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: names.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(names[index]),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editName(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addName,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final String? initialName;
  final Function(String name) onSave;

  const _NameDialog({
    this.initialName,
    required this.onSave,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.initialName != null ? 'Name bearbeiten' : 'Neuer Name'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final name = _controller.text;
            if (name.isNotEmpty) {
              widget.onSave(name);
              Navigator.pop(context);
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
