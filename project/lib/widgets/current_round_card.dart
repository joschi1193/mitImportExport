import 'package:flutter/material.dart';
import '../models/fine.dart';

class CurrentRoundCard extends StatelessWidget {
  final List<Fine> roundFines;
  final double currentAverage;
  final VoidCallback onSave;

  const CurrentRoundCard({
    super.key,
    required this.roundFines,
    required this.currentAverage,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Aktuelle Runde:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...roundFines.map((fine) => ListTile(
                      title: Text(fine.name),
                      subtitle: Text(fine.description),
                      trailing: Text(
                        '${fine.amount.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Aktueller Durchschnitt: ${currentAverage.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Runde speichern'),
          ),
        ],
      ),
    );
  }
}
