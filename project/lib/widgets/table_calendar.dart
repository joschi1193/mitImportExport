import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Beispiel für gespeicherte Termine
  Map<DateTime, List<String>> _events = {
    DateTime(2025, 1, 10): ['Meeting mit dem Team', 'Arzttermin'],
    DateTime(2025, 1, 15): ['Geburtstagsparty'],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kalender")),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          ..._getEventsForDay(_selectedDay).map((event) => ListTile(
                title: Text(event),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          _addEvent(context);
        },
      ),
    );
  }

  void _addEvent(BuildContext context) async {
    String? event = await _showAddEventDialog(context);
    if (event != null && event.isNotEmpty) {
      setState(() {
        if (_events[_selectedDay] != null) {
          _events[_selectedDay]!.add(event);
        } else {
          _events[_selectedDay] = [event];
        }
      });
    }
  }

  Future<String?> _showAddEventDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Termin hinzufügen'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Terminbeschreibung'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}
