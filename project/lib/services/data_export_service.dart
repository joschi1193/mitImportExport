import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/fine.dart';
import '../models/player.dart';
import '../models/predefined_fine.dart';
import '../models/settings.dart';
import '../models/attendance.dart';

class DataExportService {
  Future<void> exportData({
    required BuildContext context,
    required List<Fine> fines,
    required List<Player> players,
    required List<PredefinedFine> predefinedFines,
    required Settings settings,
    required List<Attendance> attendance,
    required Map<String, double> overpayments,
    Map<String, dynamic>? calendarEvents,
  }) async {
    try {
      // Hole die SharedPreferences Instanz
      final prefs = await SharedPreferences.getInstance();

      // Lade die Kalenderdaten
      final calendarEventsString = prefs.getString('Termine');
      Map<String, dynamic> calendarData = {};
      if (calendarEventsString != null) {
        calendarData = jsonDecode(calendarEventsString);
      }

      // Lade die gespeicherten Strafen
      final storedFinesString = prefs.getString('fines');
      List<Fine> allFines = fines;
      if (storedFinesString != null) {
        final List<dynamic> storedFines = jsonDecode(storedFinesString);
        allFines = storedFines.map((json) => Fine.fromJson(json)).toList();
      }

      // Lade die gespeicherte Anwesenheit
      final storedAttendanceString = prefs.getString('attendance');
      List<Attendance> allAttendance = attendance;
      if (storedAttendanceString != null) {
        final List<dynamic> storedAttendance =
            jsonDecode(storedAttendanceString);
        allAttendance =
            storedAttendance.map((json) => Attendance.fromJson(json)).toList();
      }

      // Lade die gespeicherten Überzahlungen
      final storedOverpaymentsString = prefs.getString('overpayments');
      Map<String, double> allOverpayments = overpayments;
      if (storedOverpaymentsString != null) {
        final Map<String, dynamic> storedOverpayments =
            jsonDecode(storedOverpaymentsString);
        allOverpayments = storedOverpayments
            .map((key, value) => MapEntry(key, (value as num).toDouble()));
      }

      final data = {
        'metadata': {
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'full_backup',
          'appVersion': '1.0.0',
        },
        'data': {
          'fines': allFines.map((f) => f.toJson()).toList(),
          'players': players.map((p) => p.toJson()).toList(),
          'predefinedFines': predefinedFines.map((pf) => pf.toJson()).toList(),
          'settings': settings.toJson(),
          'attendance': allAttendance.map((a) => a.toJson()).toList(),
          'overpayments': allOverpayments,
          'calendarEvents': calendarData,
          'statistics': _calculateStatistics(allFines),
          'totalFines': allFines.fold(0.0, (sum, fine) => sum + fine.amount),
          'totalPaid': allFines
              .where((f) => f.isPaid)
              .fold(0.0, (sum, fine) => sum + fine.amount),
          'totalUnpaid': allFines
              .where((f) => !f.isPaid)
              .fold(0.0, (sum, fine) => sum + fine.amount),
          'attendanceStats': _calculateAttendanceStats(allAttendance),
        }
      };

      final jsonString = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${directory.path}/schocken_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _calculateStatistics(List<Fine> fines) {
    final stats = <String, dynamic>{
      'finesByType': <String, int>{},
      'finesByPlayer': <String, int>{},
      'amountsByPlayer': <String, double>{},
      'monthlyTotals': <String, double>{},
    };

    for (final fine in fines) {
      // Zähle Strafen nach Typ
      stats['finesByType'][fine.description] =
          (stats['finesByType'][fine.description] ?? 0) + 1;

      // Zähle Strafen nach Spieler
      stats['finesByPlayer'][fine.name] =
          (stats['finesByPlayer'][fine.name] ?? 0) + 1;

      // Summiere Beträge nach Spieler
      stats['amountsByPlayer'][fine.name] =
          (stats['amountsByPlayer'][fine.name] ?? 0.0) + fine.amount;

      // Summiere Beträge nach Monat
      final monthKey =
          '${fine.date.year}-${fine.date.month.toString().padLeft(2, '0')}';
      stats['monthlyTotals'][monthKey] =
          (stats['monthlyTotals'][monthKey] ?? 0.0) + fine.amount;
    }

    return stats;
  }

  Map<String, dynamic> _calculateAttendanceStats(List<Attendance> attendance) {
    final stats = <String, dynamic>{
      'totalAttendance': <String, Map<String, int>>{},
      'monthlyAttendance': <String, Map<String, int>>{},
    };

    for (final record in attendance) {
      // Gesamtanwesenheit pro Person
      if (!stats['totalAttendance'].containsKey(record.name)) {
        stats['totalAttendance'][record.name] = {
          'present': 0,
          'late': 0,
          'absent': 0,
        };
      }
      stats['totalAttendance'][record.name]
          [record.status.toString().split('.').last]++;

      // Monatliche Anwesenheit
      final monthKey =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      if (!stats['monthlyAttendance'].containsKey(monthKey)) {
        stats['monthlyAttendance'][monthKey] = {
          'present': 0,
          'late': 0,
          'absent': 0,
        };
      }
      stats['monthlyAttendance'][monthKey]
          [record.status.toString().split('.').last]++;
    }

    return stats;
  }

  Future<Map<String, dynamic>> importData(String jsonString) async {
    try {
      debugPrint('Starting import...');
      final data = jsonDecode(jsonString);

      if (data['metadata'] == null || data['data'] == null) {
        throw const FormatException('Ungültiges Backup-Format');
      }

      final backupData = data['data'];
      final storedData = backupData['storedData'];

      // Speichere zuerst alle SharedPreferences-Daten
      final prefs = await SharedPreferences.getInstance();
      if (storedData != null) {
        for (final key in storedData.keys) {
          final value = storedData[key];
          if (value != null) {
            if (value is Map || value is List) {
              await prefs.setString(key, jsonEncode(value));
            } else if (value is String) {
              await prefs.setString(key, value);
            } else if (value is int) {
              await prefs.setInt(key, value);
            } else if (value is double) {
              await prefs.setDouble(key, value);
            } else if (value is bool) {
              await prefs.setBool(key, value);
            }
          }
        }
      }

      // Konvertiere die Hauptdaten
      final settings =
          Settings.fromJson(Map<String, dynamic>.from(backupData['settings']));
      final players = (backupData['players'] as List)
          .map((p) => Player.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      final predefinedFines = (backupData['predefinedFines'] as List)
          .map((pf) => PredefinedFine.fromJson(Map<String, dynamic>.from(pf)))
          .toList();
      final fines = (backupData['fines'] as List)
          .map((f) => Fine.fromJson(Map<String, dynamic>.from(f)))
          .toList();
      final attendance = (backupData['attendance'] as List)
          .map((a) => Attendance.fromJson(Map<String, dynamic>.from(a)))
          .toList();

      // Sicheres Parsen der Überzahlungen
      Map<String, double> overpayments = {};
      if (backupData['overpayments'] != null) {
        final overpaymentData =
            backupData['overpayments'] as Map<String, dynamic>;
        overpayments = overpaymentData.map((key, value) => MapEntry(key,
            (value is int) ? value.toDouble() : (value as num).toDouble()));
      }

      // Kalender-Events direkt aus den Hauptdaten importieren
      final calendarEvents = backupData['calendarEvents'] != null
          ? Map<String, List<String>>.from((backupData['calendarEvents'] as Map)
              .map((key, value) => MapEntry(
                    key,
                    (value as List).cast<String>(),
                  )))
          : <String, List<String>>{};

      return {
        'settings': settings,
        'players': players,
        'predefinedFines': predefinedFines,
        'fines': fines,
        'attendance': attendance,
        'overpayments': overpayments,
        'calendarEvents': calendarEvents,
      };
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }
}
