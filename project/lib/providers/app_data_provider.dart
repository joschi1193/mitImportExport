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
  Map<String, List<String>> _calendarEvents = {};

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
  Map<String, List<String>> get calendarEvents =>
      Map.unmodifiable(_calendarEvents);

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

  Future<void> updateCalendarEvents(Map<String, List<String>> events) async {
    _calendarEvents = events;
    await storageService.saveCalendarEvents(events);
    notifyListeners();
  }

  Future<void> resetData() async {
    try {
      // Speichere die aktuellen Namen und vordefinierten Strafen
      final currentPlayers = List<Player>.from(_players);
      final currentPredefinedFines =
          List<PredefinedFine>.from(_predefinedFines);

      // Setze alle Datenstrukturen auf ihre Standardwerte
      _fines = [];
      _attendance = [];
      _overpayments = {};
      _calendarEvents = {};
      _settings = const Settings(
        baseFineAmount: 15.0, // Standardwert für Grundbetrag
        previousYearsBalance: 0.0, // Setze Kassenstand auf 0
      );

      // Stelle die Namen und vordefinierten Strafen wieder her
      _players = currentPlayers;
      _predefinedFines = currentPredefinedFines;

      // Speichere den neuen Zustand
      await Future.wait([
        storageService.saveFines([]), // Leere Liste für Strafen
        storageService.saveAttendance([]), // Leere Liste für Anwesenheit
        storageService.saveOverpayments({}), // Leere Map für Überzahlungen
        storageService.saveCalendarEvents({}), // Leere Map für Kalendereinträge
        storageService.saveSettings(_settings), // Neue Settings
        storageService.savePlayers(_players), // Behalte die Spieler
        storageService.savePredefinedFines(
            _predefinedFines), // Behalte die vordefinierten Strafen
      ]);

      // Lade die Daten neu, um sicherzustellen, dass alles korrekt zurückgesetzt wurde
      await _loadData();

      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting data: $e');
      rethrow;
    }
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
        calendarEvents: _calendarEvents,
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

      // Speichere die importierten Daten temporär
      final newSettings = importedData['settings'] as Settings;
      final newPlayers = importedData['players'] as List<Player>;
      final newPredefinedFines =
          importedData['predefinedFines'] as List<PredefinedFine>;
      final newFines = importedData['fines'] as List<Fine>;
      final newAttendance = importedData['attendance'] as List<Attendance>;
      final newOverpayments =
          importedData['overpayments'] as Map<String, double>;
      final newCalendarEvents =
          importedData['calendarEvents'] as Map<String, List<String>>;

      // Lösche alle existierenden Daten
      await storageService.clearAllData();

      // Speichere die neuen Daten
      await Future.wait([
        storageService.saveSettings(newSettings),
        storageService.savePlayers(newPlayers),
        storageService.savePredefinedFines(newPredefinedFines),
        storageService.saveFines(newFines),
        storageService.saveAttendance(newAttendance),
        storageService.saveOverpayments(newOverpayments),
        storageService.saveCalendarEvents(newCalendarEvents),
      ]);

      // Aktualisiere die lokalen Variablen
      _settings = newSettings;
      _players = newPlayers;
      _predefinedFines = newPredefinedFines;
      _fines = newFines;
      _attendance = newAttendance;
      _overpayments = newOverpayments;
      _calendarEvents = newCalendarEvents;

      debugPrint('\n=== IMPORT STATE DEBUG ===');
      debugPrint('Players: ${_players.length}');
      debugPrint('Fines: ${_fines.length}');
      debugPrint('Attendance: ${_attendance.length}');
      debugPrint('PredefinedFines: ${_predefinedFines.length}');
      debugPrint('Overpayments: ${_overpayments.length}');
      debugPrint('=====================\n');

      notifyListeners();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  Future<void> _loadData() async {
    _settings = await storageService.loadSettings();
    _players = await storageService.loadPlayers();
    _predefinedFines = await storageService.loadPredefinedFines();
    _fines = await storageService.loadFines();
    _attendance = await storageService.loadAttendance();
    _overpayments = await storageService.loadOverpayments();
    _calendarEvents = await storageService.loadCalendarEvents();
    notifyListeners();
  }
}
