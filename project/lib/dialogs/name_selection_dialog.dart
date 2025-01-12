import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';

class NameSelectionDialog extends StatefulWidget {
  final String title;
  final bool multiSelect;
  final List<String>? preselectedNames;

  const NameSelectionDialog({
    super.key,
    required this.title,
    this.multiSelect = false,
    this.preselectedNames,
  });

  @override
  State<NameSelectionDialog> createState() => _NameSelectionDialogState();
}

class _NameSelectionDialogState extends State<NameSelectionDialog> {
  final Set<String> _selectedNames = {};

  @override
  Widget build(BuildContext context) {
    final names =
        widget.preselectedNames ?? Provider.of<AppDataProvider>(context).names;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: names.map((name) {
              final isSelected = _selectedNames.contains(name);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 96) / 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.multiSelect) {
                      setState(() {
                        if (isSelected) {
                          _selectedNames.remove(name);
                        } else {
                          _selectedNames.add(name);
                        }
                      });
                    } else {
                      Navigator.pop(context, name);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: isSelected ? Colors.blue : null,
                    foregroundColor: isSelected ? Colors.white : null,
                  ),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        if (widget.multiSelect)
          TextButton(
            onPressed: _selectedNames.isEmpty
                ? null
                : () => Navigator.pop(context, _selectedNames.toList()),
            child: const Text('Bestätigen'),
          ),
      ],
    );
  }
}
