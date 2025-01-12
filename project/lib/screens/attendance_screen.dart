import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/attendance.dart';
import '../models/fine.dart';
import '../providers/app_data_provider.dart';

class AttendanceScreen extends StatefulWidget {
  final Function(List<Fine>) onAddFines;
  final Function(List<Attendance>) onSaveAttendance;

  const AttendanceScreen({
    super.key,
    required this.onAddFines,
    required this.onSaveAttendance,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<String, AttendanceStatus> _attendance = {};
  final List<Fine> _fines = [];
  bool _hasSubmitted = false;
  double _averageFine = 0.0;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final names = appData.names;

    if (names.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Bitte füge zuerst Namen in den Einstellungen hinzu.'),
        ),
      );
    }

    // Initialize attendance map for new names
    for (final name in names) {
      if (!_attendance.containsKey(name)) {
        _attendance[name] = AttendanceStatus.present;
      }
    }

    // Remove attendance entries for removed names
    _attendance.removeWhere((name, _) => !names.contains(name));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheit'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: names.length,
              itemBuilder: (context, index) {
                final name = names[index];
                final status = _attendance[name] ?? AttendanceStatus.present;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text(_getStatusText(status)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: status == AttendanceStatus.present
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () => _updateStatus(
                            name,
                            AttendanceStatus.present,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.access_time,
                            color: status == AttendanceStatus.late
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          onPressed: () => _updateStatus(
                            name,
                            AttendanceStatus.late,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: status == AttendanceStatus.absent
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () => _updateStatus(
                            name,
                            AttendanceStatus.absent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_hasSubmitted) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Durchschnitt der Tagesstrafen: ${_averageFine.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Die Anwesenheit wurde gespeichert.',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _hasSubmitted ? null : _submitAttendance,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Anwesenheit speichern'),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Anwesend';
      case AttendanceStatus.late:
        return 'Zu spät';
      case AttendanceStatus.absent:
        return 'Abwesend';
    }
  }

  void _updateStatus(String name, AttendanceStatus status) {
    if (_hasSubmitted) return;

    setState(() {
      _attendance[name] = status;
    });
  }

  void _submitAttendance() {
    final now = DateTime.now();
    final attendanceList = <Attendance>[];
    _fines.clear();
    final appData = Provider.of<AppDataProvider>(context, listen: false);
    final baseFineAmount = appData.baseFineAmount;

    // Add attendance records and base fines for all players
    for (final entry in _attendance.entries) {
      final name = entry.key;
      final status = entry.value;
      final isGuest = appData.isGuest(name);

      // Create attendance record
      attendanceList.add(Attendance(
        name: name,
        date: now,
        status: status,
        baseFine: baseFineAmount,
        averageFine: 0.0,
      ));

      // Add base fine for present/late players (excluding guests)
      if (!isGuest) {
        if (status != AttendanceStatus.absent) {
          _fines.add(Fine(
            name: name,
            amount: baseFineAmount,
            date: now,
            description: 'Grundbetrag',
          ));
        } else {
          // Add base fine for absent players
          _fines.add(Fine(
            name: name,
            amount: baseFineAmount,
            date: now,
            description: 'Grundbetrag (Abwesend)',
          ));
        }
      }
    }

    // Calculate and add average fines for absent players
    final averageFine = _calculateAverageFine();
    setState(() => _averageFine = averageFine);

    if (averageFine > 0.01) {
      for (final entry in _attendance.entries) {
        final name = entry.key;
        final status = entry.value;
        final isGuest = appData.isGuest(name);

        if (status == AttendanceStatus.absent && !isGuest) {
          // Add average fine for absent players
          _fines.add(Fine(
            name: name,
            amount: averageFine,
            date: now,
            description: 'Durchschnitt der Tagesstrafen (Abwesend)',
          ));
        }
      }
    }

    widget.onAddFines(_fines);
    widget.onSaveAttendance(attendanceList);
    setState(() => _hasSubmitted = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anwesenheit wurde gespeichert')),
    );
  }

  double _calculateAverageFine() {
    final presentCount = _attendance.values
        .where((status) => status != AttendanceStatus.absent)
        .length;

    if (presentCount == 0) return 0;

    final totalFines = _fines
        .where((fine) => !fine.description.contains('Grundbetrag'))
        .fold<double>(0, (sum, fine) => sum + fine.amount);

    return totalFines / presentCount;
  }
}
