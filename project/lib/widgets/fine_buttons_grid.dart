import 'package:flutter/material.dart';
import '../models/predefined_fine.dart';
import 'fine_button.dart';

class FineButtonsGrid extends StatelessWidget {
  final List<PredefinedFine> predefinedFines;
  final Function(BuildContext, PredefinedFine) onFineSelected;

  const FineButtonsGrid({
    super.key,
    required this.predefinedFines,
    required this.onFineSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: predefinedFines.length,
        itemBuilder: (context, index) {
          final fine = predefinedFines[index];
          return FineButton(
            fine: fine,
            onPressed: () => onFineSelected(context, fine),
          );
        },
      ),
    );
  }
}
