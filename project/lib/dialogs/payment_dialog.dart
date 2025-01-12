import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final String name;
  final double total;

  const PaymentDialog({
    super.key,
    required this.name,
    required this.total,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _controller = TextEditingController();
  static const List<int> presetAmounts = [
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.total.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Zahlung von ${widget.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Offene Strafen: ${widget.total.toStringAsFixed(2)}€'),
          const SizedBox(height: 16),
          SizedBox(
            height: 100, // Reduzierte Höhe
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presetAmounts
                    .map(
                      (amount) => SizedBox(
                        width: 56, // Feste Breite für kompakte Buttons
                        height: 36, // Feste Höhe für kompakte Buttons
                        child: ElevatedButton(
                          onPressed: () {
                            _controller.text = amount.toString();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('$amount€'),
                        ),
                      ),
                    )
                    .toList(),
              ),
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
            final amount = double.tryParse(_controller.text);
            if (amount != null && amount > 0) {
              Navigator.pop(context, amount);
            }
          },
          child: const Text('Bezahlen'),
        ),
      ],
    );
  }
}
