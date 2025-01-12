// lib/providers/current_round_provider.dart
import 'package:flutter/material.dart';
import '../models/fine.dart';

class CurrentRoundProvider extends ChangeNotifier {
  final List<Fine> _roundFines = [];

  List<Fine> get roundFines => List.unmodifiable(_roundFines);
  bool get hasRoundFines => _roundFines.isNotEmpty;

  void addFine(Fine fine) {
    _roundFines.add(fine);
    notifyListeners();
  }

  void clearRound() {
    _roundFines.clear();
    notifyListeners();
  }

  double calculateCurrentAverage(List<String> presentPlayers) {
    if (presentPlayers.isEmpty || _roundFines.isEmpty) return 0;

    final totalFines = _roundFines.fold<double>(
      0,
      (sum, fine) =>
          sum + (fine.description != 'Grundbetrag' ? fine.amount : 0),
    );

    return totalFines / presentPlayers.length;
  }
}
