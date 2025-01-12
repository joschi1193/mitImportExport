import 'package:flutter/material.dart';
import '../models/predefined_fine.dart';

class FineButton extends StatelessWidget {
  final PredefinedFine fine;
  final VoidCallback onPressed;

  const FineButton({
    super.key,
    required this.fine,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            fine.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!fine.isCustomAmount) ...[
            const SizedBox(height: 2),
            Text(
              '${fine.amount.toStringAsFixed(2)}€',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
