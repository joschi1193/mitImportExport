import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fine.dart';
import '../dialogs/payment_dialog.dart';
import '../providers/app_data_provider.dart';

class FinesTableScreen extends StatelessWidget {
  final List<Fine> fines;
  final Function(String, double) onPayment;
  final Function(Fine) onUpdateFine;

  const FinesTableScreen({
    super.key,
    required this.fines,
    required this.onPayment,
    required this.onUpdateFine,
  });

  Map<String, List<Fine>> _groupFinesByName(List<String> names) {
    final groupedFines = <String, List<Fine>>{};
    for (final name in names) {
      groupedFines[name] = fines
          .where((fine) => fine.name == name && !fine.isPaid)
          .where((fine) =>
              !fine.description.contains('Durchschnitt') || fine.amount > 0.01)
          .toList();
    }
    return groupedFines;
  }

  Future<void> _showPaymentDialog(
      BuildContext context, String name, double total) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => PaymentDialog(
        name: name,
        total: total,
      ),
    );

    if (amount != null && amount > 0) {
      onPayment(name, amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final groupedFines = _groupFinesByName(appData.names);
    final hasUnpaidFines = groupedFines.values.any((fines) => fines.isNotEmpty);

    if (!hasUnpaidFines) {
      return const Center(
        child: Text(
          'Keine offenen Strafen',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: groupedFines.length,
      itemBuilder: (context, index) {
        final name = groupedFines.keys.elementAt(index);
        final playerFines = groupedFines[name]!;
        if (playerFines.isEmpty) return const SizedBox.shrink();

        final total = playerFines.fold<double>(
          0,
          (sum, fine) => sum + fine.amount,
        );

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name),
                Text(
                  '${total.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: [
              ...playerFines.map((fine) => ListTile(
                    title: Text(fine.description),
                    trailing: Text('${fine.amount.toStringAsFixed(2)}€'),
                  )),
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () => _showPaymentDialog(context, name, total),
                    child: const Text('Bezahlen'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
