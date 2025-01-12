import '../models/fine.dart';
import '../models/attendance.dart';
import '../utils/date_utils.dart';

class XmlExportService {
  String generateDayXml({
    required String date,
    required List<Fine> fines,
    required List<Attendance> attendance,
    required Map<String, double> overpayments,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<strafenkasse>');
    buffer.writeln('  <tag datum="$date">');

    // Anwesenheit
    if (attendance.isNotEmpty) {
      buffer.writeln('    <anwesenheit>');
      for (final record in attendance) {
        buffer.writeln(
            '      <person name="${_escapeXml(record.name)}" status="${record.status.toString().split('.').last}"/>');
      }
      buffer.writeln('    </anwesenheit>');
    }

    // Strafen
    if (fines.isNotEmpty) {
      buffer.writeln('    <strafen>');
      for (final fine in fines) {
        buffer.writeln(
            '      <strafe name="${_escapeXml(fine.name)}" betrag="${fine.amount}" beschreibung="${_escapeXml(fine.description)}" bezahlt="${fine.isPaid}"/>');
      }
      buffer.writeln('    </strafen>');
    }

    // Spenden
    if (overpayments.isNotEmpty) {
      buffer.writeln('    <ueberzahlungen>');
      for (final entry in overpayments.entries) {
        buffer.writeln(
            '      <ueberzahlung name="${_escapeXml(entry.key)}" betrag="${entry.value}"/>');
      }
      buffer.writeln('    </ueberzahlungen>');
    }

    buffer.writeln('  </tag>');
    buffer.writeln('</strafenkasse>');
    return buffer.toString();
  }

  String generateOverpaymentsXml(Map<String, double> overpayments) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<strafenkasse>');
    buffer.writeln('  <ueberzahlungen>');
    for (final entry in overpayments.entries) {
      buffer.writeln(
          '    <ueberzahlung name="${_escapeXml(entry.key)}" betrag="${entry.value}"/>');
    }
    buffer.writeln('  </ueberzahlungen>');
    buffer.writeln('</strafenkasse>');
    return buffer.toString();
  }

  Map<String, List<dynamic>> groupItemsByDate(
      List<Fine> fines, List<Attendance> attendance) {
    final groupedItems = <String, List<dynamic>>{};

    for (var fine in fines) {
      final key = formatDate(fine.date);
      groupedItems.putIfAbsent(key, () => []).add(fine);
    }

    for (var record in attendance) {
      final key = formatDate(record.date);
      groupedItems.putIfAbsent(key, () => []).add(record);
    }

    return Map.fromEntries(
        groupedItems.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
