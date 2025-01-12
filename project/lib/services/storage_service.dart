import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fine.dart';
import '../models/player.dart';
import '../models/predefined_fine.dart';
import '../models/settings.dart';
import '../models/attendance.dart';

class StorageService {
  static const String _settingsKey = 'settings';
  static const String _playersKey = 'players';
  static const String _predefinedFinesKey = 'predefinedFines';
  static const String _finesKey = 'fines';
  static const String _attendanceKey = 'attendance';
  static const String _overpaymentsKey = 'overpayments';
  static const String _calendarEventsKey = 'Termine';

  late final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final service = StorageService();
    service._prefs = await SharedPreferences.getInstance();
    return service;
  }

  // Settings
  Future<void> saveSettings(Settings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<Settings> loadSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) return const Settings();
    return Settings.fromJson(jsonDecode(jsonString));
  }

  // Players
  Future<void> savePlayers(List<Player> players) async {
    final jsonString = jsonEncode(players.map((p) => p.toJson()).toList());
    await _prefs.setString(_playersKey, jsonString);
  }

  Future<List<Player>> loadPlayers() async {
    final jsonString = _prefs.getString(_playersKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Player.fromJson(json)).toList();
  }

  // Predefined Fines
  Future<void> savePredefinedFines(List<PredefinedFine> fines) async {
    final jsonString = jsonEncode(fines.map((f) => f.toJson()).toList());
    await _prefs.setString(_predefinedFinesKey, jsonString);
  }

  Future<List<PredefinedFine>> loadPredefinedFines() async {
    final jsonString = _prefs.getString(_predefinedFinesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => PredefinedFine.fromJson(json)).toList();
  }

  // Fines
  Future<void> saveFines(List<Fine> fines) async {
    final jsonString = jsonEncode(fines.map((f) => f.toJson()).toList());
    await _prefs.setString(_finesKey, jsonString);
  }

  Future<List<Fine>> loadFines() async {
    final jsonString = _prefs.getString(_finesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Fine.fromJson(json)).toList();
  }

  // Attendance
  Future<void> saveAttendance(List<Attendance> attendance) async {
    final jsonString = jsonEncode(attendance.map((a) => a.toJson()).toList());
    await _prefs.setString(_attendanceKey, jsonString);
  }

  Future<List<Attendance>> loadAttendance() async {
    final jsonString = _prefs.getString(_attendanceKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Attendance.fromJson(json)).toList();
  }

  // Overpayments
  Future<void> saveOverpayments(Map<String, double> overpayments) async {
    await _prefs.setString(_overpaymentsKey, jsonEncode(overpayments));
  }

  Future<Map<String, double>> loadOverpayments() async {
    final jsonString = _prefs.getString(_overpaymentsKey);
    if (jsonString == null) return {};
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<void> saveCalendarEvents(Map<String, List<String>> events) async {
    await _prefs.setString(_calendarEventsKey, jsonEncode(events));
  }

  Future<Map<String, List<String>>> loadCalendarEvents() async {
    final jsonString = _prefs.getString(_calendarEventsKey);
    if (jsonString == null) return {};
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return json.map((key, value) =>
        MapEntry(key, (value as List).map((e) => e.toString()).toList()));
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
  }
}
