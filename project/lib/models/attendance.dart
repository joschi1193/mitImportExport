enum AttendanceStatus { present, late, absent }

class Attendance {
  final String name;
  final DateTime date;
  final AttendanceStatus status;
  final double baseFine;
  final double averageFine;

  Attendance({
    required this.name,
    required this.date,
    required this.status,
    required this.baseFine,
    this.averageFine = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
      'status': status.toString(),
      'baseFine': baseFine,
      'averageFine': averageFine,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      name: json['name'],
      date: DateTime.parse(json['date']),
      status: _parseAttendanceStatus(json['status']),
      baseFine: json['baseFine'] ?? 15.0,
      averageFine: json['averageFine'] ?? 0.0,
    );
  }

  static AttendanceStatus _parseAttendanceStatus(String statusStr) {
    // Entferne "AttendanceStatus." vom String, falls vorhanden
    final cleanStatus = statusStr.replaceAll('AttendanceStatus.', '');

    // Konvertiere zu lowercase für case-insensitive Vergleiche
    switch (cleanStatus.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'late':
        return AttendanceStatus.late;
      case 'absent':
        return AttendanceStatus.absent;
      default:
        return AttendanceStatus.absent; // Fallback für unbekannte Werte
    }
  }
}
