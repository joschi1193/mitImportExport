enum AttendanceStatus {
  present,
  late,
  absent
}

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
    this.baseFine = 15.0,
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
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      baseFine: json['baseFine'] ?? 15.0,
      averageFine: json['averageFine'] ?? 0.0,
    );
  }
}