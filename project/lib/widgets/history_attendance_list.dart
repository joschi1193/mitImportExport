import 'package:flutter/material.dart';
import '../models/attendance.dart';

class HistoryAttendanceList extends StatelessWidget {
  final List<Attendance> attendance;

  const HistoryAttendanceList({
    super.key,
    required this.attendance,
  });

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Anwesenheit:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...attendance.map((record) => Container(
          color: _getStatusColor(record.status).withOpacity(0.2),
          child: ListTile(
            title: Text(record.name),
            trailing: Text(
              record.status.toString().split('.').last,
              style: TextStyle(
                color: _getStatusColor(record.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
      ],
    );
  }
}