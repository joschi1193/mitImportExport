import 'package:flutter/material.dart';
import '../models/fine.dart';

class HistoryFinesList extends StatelessWidget {
  final List<Fine> fines;

  const HistoryFinesList({
    super.key,
    required this.fines,
  });

  List<Fine> _filterFines(List<Fine> fines) {
    return fines
        .where((fine) =>
            !fine.description.contains('Durchschnitt') || fine.amount > 0.01)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFines = _filterFines(fines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Strafen:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...filteredFines.map((fine) => ListTile(
              title: Text(fine.name),
              subtitle: Text(fine.description),
              trailing: Text(
                '${fine.amount.toStringAsFixed(2)} €',
                style: TextStyle(
                  color: fine.isPaid ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
      ],
    );
  }
}
