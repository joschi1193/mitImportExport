import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../dialogs/password_dialog.dart';

class PreviousYearsTab extends StatefulWidget {
  const PreviousYearsTab({super.key});

  @override
  State<PreviousYearsTab> createState() => _PreviousYearsTabState();
}

class _PreviousYearsTabState extends State<PreviousYearsTab> {
  final _controller = TextEditingController();
  bool _hasChanges = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appData = Provider.of<AppDataProvider>(context);
    _controller.text = appData.previousYearsBalance.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Einnahmen aus vorherigen Jahren',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Betrag (€)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _hasChanges
                ? () async {
                    final amount = double.tryParse(_controller.text);
                    if (amount != null && amount >= 0) {
                      // Hier wird der PasswordDialog aufgerufen
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => const PasswordDialog(),
                      );

                      if (confirmed == true) {
                        if (!context.mounted) return;
                        await Provider.of<AppDataProvider>(context,
                                listen: false)
                            .updatePreviousYearsBalance(amount);

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Vorjahreseinnahmen wurden aktualisiert'),
                          ),
                        );
                        setState(() {
                          _hasChanges = false;
                        });
                      }
                    }
                  }
                : null,
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}
