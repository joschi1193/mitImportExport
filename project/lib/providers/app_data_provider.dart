import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/data_export_service.dart';
import '../models/settings.dart';
import '../models/player.dart';
import '../models/predefined_fine.dart';
import '../models/fine.dart';
import '../models/attendance.dart';

class AppDataProvider extends ChangeNotifier {
  final StorageService storageService;
  final _dataExportService = DataExportService();

  Settings _settings = const Settings();
  List<Player> _players = [];
  List<PredefinedFine> _predefinedFines = [];
  List<Fine> _fines = [];
  List<Attendance> _attendance = [];
  Map<String, double> _overpayments = {};

  AppDataProvider(this.storageService) {
    _loadData();
  }

  // Getters
  double get baseFineAmount => _settings.baseFineAmount;
  double get previousYearsBalance => _settings.previousYearsBalance;
  List<String> get names => _players.map((p) => p.name).toList();
  List<Player> get players => List.unmodifiable(_players);
  List<PredefinedFine> get predefinedFines =>
      List.unmodifiable(_predefinedFines);
  List<Fine> get fines => List.unmodifiable(_fines);
  List<Attendance> get attendance => List.unmodifiable(_attendance);
  Map<String, double> get overpayments => Map.unmodifiable(_overpayments);

  bool isGuest(String name) {
    return _players.any((p) => p.name == name && p.isGuest);
  }

  void debugPrintState() {
    debugPrint('\n=== APP STATE DEBUG ===');
    debugPrint('Players: ${_players.length}');
    debugPrint('PredefinedFines: ${_predefinedFines.length}');
    debugPrint('Fines: ${_fines.length}');
    debugPrint('Attendance: ${_attendance.length}');
    debugPrint('Overpayments: ${_overpayments.length}');
    debugPrint(
        'Settings: baseFine=${_settings.baseFineAmount}, prevYear=${_settings.previousYearsBalance}');
    debugPrint('=====================\n');
  }

  // Update methods
  Future<void> updateSettings({
    required double baseFineAmount,
    required double previousYearsBalance,
  }) async {
    _settings = Settings(
      baseFineAmount: baseFineAmount,
      previousYearsBalance: previousYearsBalance,
    );
    await storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> resetGameData() async {
    // Setze Strafen zurück
    _fines = [];
    await storageService.saveFines(_fines);

    // Setze Anwesenheit zurück
    _attendance = [];
    await storageService.saveAttendance(_attendance);

    // Setze Überzahlungen zurück
    _overpayments = {};
    await storageService.saveOverpayments(_overpayments);

    // Benachrichtige alle Listener über die Änderungen
    notifyListeners();
  }

  Future<void> updateBaseFineAmount(double amount) async {
    _settings = Settings(
      baseFineAmount: amount,
      previousYearsBalance: _settings.previousYearsBalance,
    );
    await storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updatePreviousYearsBalance(double amount) async {
    _settings = Settings(
      baseFineAmount: _settings.baseFineAmount,
      previousYearsBalance: amount,
    );
    await storageService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updatePlayers(List<Player> players) async {
    _players = players;
    await storageService.savePlayers(_players);
    notifyListeners();
  }

  Future<void> updatePredefinedFines(List<PredefinedFine> fines) async {
    _predefinedFines = fines;
    await storageService.savePredefinedFines(_predefinedFines);
    notifyListeners();
  }

  // Export/Import methods
  Future<void> exportData(BuildContext context) async {
    try {
      await _dataExportService.exportData(
        context: context,
        fines: _fines,
        players: _players,
        predefinedFines: _predefinedFines,
        settings: _settings,
        attendance: _attendance,
        overpayments: _overpayments,
      );
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  Future<void> importData(String jsonString) async {
    try {
      debugPrint('Starting import...');
      final importedData = await _dataExportService.importData(jsonString);

      // Aktualisiere zuerst die lokalen Variablen
      _settings = importedData['settings'] as Settings;
      _players = importedData['players'] as List<Player>;
      _predefinedFines =
          importedData['predefinedFines'] as List<PredefinedFine>;
      _fines = importedData['fines'] as List<Fine>;
      _attendance = importedData['attendance'] as List<Attendance>;
      _overpayments = importedData['overpayments'] as Map<String, double>;

      // Benachrichtige Listener SOFORT nach der Aktualisierung der Variablen
      notifyListeners();

      // Dann lösche die existierenden Daten
      await storageService.clearAllData();

      // Und speichere die neuen Daten
      await Future.wait([
        storageService.saveSettings(_settings),
        storageService.savePlayers(_players),
        storageService.savePredefinedFines(_predefinedFines),
        storageService.saveFines(_fines),
        storageService.saveAttendance(_attendance),
        storageService.saveOverpayments(_overpayments),
      ]);

      debugPrint('Import completed successfully');
      debugPrint('Players: ${_players.length}');
      debugPrint('Fines: ${_fines.length}');
      debugPrint('Attendance: ${_attendance.length}');
      debugPrint('PredefinedFines: ${_predefinedFines.length}');
      debugPrint('Overpayments: ${_overpayments.length}');

      // Benachrichtige Listener nochmal nach dem Speichern
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  // Private methods
  Future<void> _loadData() async {
    _settings = await storageService.loadSettings();
    _players = await storageService.loadPlayers();
    _predefinedFines = await storageService.loadPredefinedFines();
    _fines = await storageService.loadFines();
    _attendance = await storageService.loadAttendance();
    _overpayments = await storageService.loadOverpayments();
    notifyListeners();
  }
}
