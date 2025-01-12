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
  }) async {
    try {
      // Hole alle gespeicherten Daten aus SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final allStoredData = <String, dynamic>{};

      for (final key in allKeys) {
        final value = prefs.get(key);
        if (value != null) {
          try {
            // Versuche den Wert als JSON zu parsen
            allStoredData[key] = jsonDecode(value.toString());
          } catch (e) {
            // Wenn der Wert kein JSON ist, speichere ihn direkt
            allStoredData[key] = value;
          }
        }
      }

      // Berechne zusätzliche statistische Daten
      final statistics = _calculateStatistics(fines);

      final data = {
        'metadata': {
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'full_backup',
          'appVersion': '1.0.0', // Füge die App-Version hinzu
        },
        'data': {
          // Hauptdaten
          'fines': fines.map((f) => f.toJson()).toList(),
          'players': players.map((p) => p.toJson()).toList(),
          'predefinedFines': predefinedFines.map((pf) => pf.toJson()).toList(),
          'settings': settings.toJson(),
          'attendance': attendance.map((a) => a.toJson()).toList(),
          'overpayments': overpayments,

          // Zusätzliche Daten
          'statistics': statistics,
          'storedData': allStoredData,

          // Kalender-Events
          'calendarEvents': allStoredData['calendar_events'] ?? {},

          // Berechnete Summen
          'totalFines': fines.fold(0.0, (sum, fine) => sum + fine.amount),
          'totalPaid': fines
              .where((f) => f.isPaid)
              .fold(0.0, (sum, fine) => sum + fine.amount),
          'totalUnpaid': fines
              .where((f) => !f.isPaid)
              .fold(0.0, (sum, fine) => sum + fine.amount),

          // Anwesenheitsstatistiken
          'attendanceStats': _calculateAttendanceStats(attendance),
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

      final overpayments = Map<String, double>.from(
          (backupData['overpayments'] as Map).map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble())));

      // Kalender-Events importieren
      if (backupData['calendarEvents'] != null) {
        final calendarEvents = Map<String, List<String>>.from(
            (backupData['calendarEvents'] as Map).map((key, value) => MapEntry(
                key.toString(),
                (value as List).map((e) => e.toString()).toList())));
        await prefs.setString('calendar_events', jsonEncode(calendarEvents));
      }

      return {
        'settings': settings,
        'players': players,
        'predefinedFines': predefinedFines,
        'fines': fines,
        'attendance': attendance,
        'overpayments': overpayments,
      };
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }
}
