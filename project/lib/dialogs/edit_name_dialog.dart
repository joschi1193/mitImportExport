import 'package:flutter/material.dart';
import '../models/player.dart';

class EditNameDialog extends StatefulWidget {
  final Player? player;

  const EditNameDialog({
    super.key,
    this.player,
  });

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late final TextEditingController _controller;
  late bool _isGuest;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.player?.name);
    _isGuest = widget.player?.isGuest ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.player == null ? 'Neuer Name' : 'Name bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Gast'),
            subtitle: const Text('Muss keinen Grundbetrag zahlen'),
            value: _isGuest,
            onChanged: (value) {
              setState(() {
                _isGuest = value ?? false;
              });
            },
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
            if (_controller.text.isNotEmpty) {
              Navigator.pop(
                context,
                Player(
                  name: _controller.text,
                  isGuest: _isGuest,
                ),
              );
            }
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
