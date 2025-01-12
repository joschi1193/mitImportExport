// lib/controllers/fine_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fine.dart';
import '../models/attendance.dart';
import '../models/predefined_fine.dart';
import '../dialogs/name_selection_dialog.dart';
import '../dialogs/confirmation_dialog.dart';
import '../dialogs/custom_amount_dialog.dart';
import '../providers/app_data_provider.dart';
import '../providers/current_round_provider.dart';
import '../utils/fine_utils.dart';

class FineController {
  final List<Fine> fines;
  final List<Attendance> attendance;
  final Function(Fine) onAddFine;
  final Function() onUpdateUnpaidTotals;
  final BuildContext context;

  FineController({
    required this.fines,
    required this.attendance,
    required this.onAddFine,
    required this.onUpdateUnpaidTotals,
    required this.context,
  });

  Map<String, double> calculateUnpaidTotals(BuildContext context) {
    final totals = <String, double>{};
    for (final name
        in Provider.of<AppDataProvider>(context, listen: false).names) {
      final unpaidAmount = calculateUnpaidAmount(fines, name);
      if (unpaidAmount > 0) {
        totals[name] = unpaidAmount;
      }
    }
    return totals;
  }

  Future<void> handleFineButton(
      BuildContext context, PredefinedFine fine) async {
    final presentAndLatePlayers = getPresentPlayers(attendance);

    if (presentAndLatePlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte erst die Anwesenheit speichern!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fine.name == 'Schock Hand') {
      await _handleSchockHand(context, fine, presentAndLatePlayers);
      return;
    }

    final selectedName = await showDialog<String>(
      context: context,
      builder: (context) => NameSelectionDialog(
        title: 'Wer muss zahlen?',
        multiSelect: false,
        preselectedNames: presentAndLatePlayers,
      ),
    );

    if (selectedName == null) return;

    if (fine.isCustomAmount) {
      await _handleCustomAmount(context, selectedName, fine);
    } else {
      await _handleFixedAmount(context, selectedName, fine);
    }
  }

  Future<void> _handleSchockHand(
    BuildContext context,
    PredefinedFine fine,
    List<String> presentAndLatePlayers,
  ) async {
    final schockHandPlayer = await showDialog<String>(
      context: context,
      builder: (context) => NameSelectionDialog(
        title: 'Wer hat Schock Hand?',
        multiSelect: false,
        preselectedNames: presentAndLatePlayers,
      ),
    );

    if (schockHandPlayer == null) return;

    for (final name in presentAndLatePlayers) {
      if (name != schockHandPlayer) {
        _addFine(name, fine.amount, '${fine.name} (${schockHandPlayer})');
      }
    }
  }

  Future<void> _handleCustomAmount(
    BuildContext context,
    String name,
    PredefinedFine fine,
  ) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => CustomAmountDialog(
        name: name,
        fineName: fine.name,
      ),
    );

    if (amount != null) {
      _addFine(name, amount, fine.name);
    }
  }

  Future<void> _handleFixedAmount(
    BuildContext context,
    String name,
    PredefinedFine fine,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        name: name,
        fine: fine,
      ),
    );

    if (confirmed == true) {
      _addFine(name, fine.amount, fine.name);
    }
  }

  void _addFine(String name, double amount, String description) {
    if (description == 'Grundbetrag' &&
        Provider.of<AppDataProvider>(context, listen: false).isGuest(name)) {
      return;
    }

    final newFine = Fine(
      name: name,
      amount: amount,
      date: DateTime.now(),
      description: description,
    );

    Provider.of<CurrentRoundProvider>(context, listen: false).addFine(newFine);
    onUpdateUnpaidTotals();
  }

  void saveRound(BuildContext context) {
    final currentRoundProvider =
        Provider.of<CurrentRoundProvider>(context, listen: false);
    final roundFines = currentRoundProvider.roundFines;
    final presentPlayers = getPresentPlayers(attendance);
    final appData = Provider.of<AppDataProvider>(context, listen: false);

    for (final fine in roundFines) {
      onAddFine(fine);
    }

    final average =
        currentRoundProvider.calculateCurrentAverage(presentPlayers);
    final now = DateTime.now();

    for (final name in appData.names) {
      if (!presentPlayers.contains(name) && !appData.isGuest(name)) {
        onAddFine(Fine(
          name: name,
          amount: 15.0,
          date: now,
          description: 'Grundbetrag (Abwesend)',
        ));

        if (average > 0) {
          onAddFine(Fine(
            name: name,
            amount: average,
            date: now,
            description: 'Durchschnitt der Tagesstrafen (Abwesend)',
          ));
        }
      }
    }

    currentRoundProvider.clearRound();
    onUpdateUnpaidTotals();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Runde gespeichert. Durchschnitt: ${average.toStringAsFixed(2)}€'),
      ),
    );
  }
}
