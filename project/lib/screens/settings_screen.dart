import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_data_provider.dart';
import '../models/predefined_fine.dart';
import '../models/player.dart';
import '../dialogs/edit_name_dialog.dart';
import '../dialogs/edit_fine_dialog.dart';
import '../dialogs/password_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  int _selectedIndex = -1;

  Future<void> _resetData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten zurücksetzen'),
        content: const Text(
          'Möchtest du wirklich alle Strafen, Anwesenheiten und Überzahlungen zurücksetzen? '
          'Die Namen und vordefinierten Strafen bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final appData = Provider.of<AppDataProvider>(context, listen: false);

      // Setze die Daten zurück, aber behalte Namen und vordefinierte Strafen
      await appData.resetData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alle Daten wurden zurückgesetzt'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Linke Seite - Navigationsliste
          SizedBox(
            width: 200,
            child: ListView(
              children: [
                _buildNavItem(0, 'Namen', Icons.people),
                _buildNavItem(1, 'Strafen', Icons.attach_money),
                _buildNavItem(2, 'Bis 01.2025', Icons.account_balance),
                _buildNavItem(3, 'Kalender', Icons.calendar_today),
                _buildNavItem(4, 'Daten', Icons.storage),
                _buildNavItem(5, 'Zurücksetzen', Icons.restore),
              ],
            ),
          ),
          // Vertikale Trennlinie
          const VerticalDivider(width: 1),
          // Rechte Seite - Inhalt
          Expanded(
            child: _selectedIndex == -1
                ? const Center(
                    child: Text('Bitte wähle eine Option aus'),
                  )
                : Stack(
                    children: [
                      _buildContent(),
                      if (_isLoading)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _NamesTab();
      case 1:
        return const _FinesTab();
      case 2:
        return const _BaseFineTab();
      case 3:
        return const _CalendarTab();
      case 4:
        return _DataTab();
      case 5:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hier kannst du alle Daten zurücksetzen.\n'
                'Die Namen und vordefinierten Strafen bleiben erhalten.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _resetData(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: const Text('Daten zurücksetzen'),
              ),
            ],
          ),
        );
      default:
        return const Center(
          child: Text('Bitte wähle eine Option aus'),
        );
    }
  }
}

class _NamesTab extends StatelessWidget {
  const _NamesTab();

  Future<bool> _checkPassword(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PasswordDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final players = appData.players;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: player.isGuest
                      ? const Text(
                          'Gast',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final editedPlayer = await showDialog<Player>(
                            context: context,
                            builder: (context) =>
                                EditNameDialog(player: player),
                          );

                          if (editedPlayer != null) {
                            final newPlayers = List<Player>.from(players);
                            newPlayers[index] = editedPlayer;
                            appData.updatePlayers(newPlayers);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          if (await _checkPassword(context)) {
                            final newPlayers = List<Player>.from(players);
                            newPlayers.removeAt(index);
                            appData.updatePlayers(newPlayers);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              final newPlayer = await showDialog<Player>(
                context: context,
                builder: (context) => const EditNameDialog(),
              );

              if (newPlayer != null) {
                final newPlayers = List<Player>.from(players)..add(newPlayer);
                appData.updatePlayers(newPlayers);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Neuen Namen hinzufügen'),
          ),
        ),
      ],
    );
  }
}

class _FinesTab extends StatelessWidget {
  const _FinesTab();

  Future<bool> _checkPassword(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PasswordDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final fines = appData.predefinedFines;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: fines.length,
            itemBuilder: (context, index) {
              final fine = fines[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    fine.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    fine.isCustomAmount
                        ? 'Benutzerdefinierter Betrag'
                        : '${fine.amount.toStringAsFixed(2)}€',
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final editedFine = await showDialog<PredefinedFine>(
                            context: context,
                            builder: (context) => EditFineDialog(fine: fine),
                          );

                          if (editedFine != null) {
                            final newFines = List<PredefinedFine>.from(fines);
                            newFines[index] = editedFine;
                            appData.updatePredefinedFines(newFines);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          if (await _checkPassword(context)) {
                            final newFines = List<PredefinedFine>.from(fines);
                            newFines.removeAt(index);
                            appData.updatePredefinedFines(newFines);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              final newFine = await showDialog<PredefinedFine>(
                context: context,
                builder: (context) => const EditFineDialog(),
              );

              if (newFine != null) {
                final newFines = List<PredefinedFine>.from(fines)..add(newFine);
                appData.updatePredefinedFines(newFines);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Neue Strafe hinzufügen'),
          ),
        ),
      ],
    );
  }
}

class _BaseFineTab extends StatefulWidget {
  const _BaseFineTab();

  @override
  State<_BaseFineTab> createState() => _BaseFineTabState();
}

class _BaseFineTabState extends State<_BaseFineTab> {
  final _baseFineController = TextEditingController();
  final _previousYearsController = TextEditingController();
  bool _hasChanges = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appData = Provider.of<AppDataProvider>(context);
    _baseFineController.text = appData.baseFineAmount.toString();
    _previousYearsController.text = appData.previousYearsBalance.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Einnahmen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _previousYearsController,
            decoration: const InputDecoration(
              labelText: 'Kassenstand bis 2025 (€)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _hasChanges
                ? () async {
                    final baseFine = double.tryParse(_baseFineController.text);
                    final previousYears =
                        double.tryParse(_previousYearsController.text);

                    if (baseFine != null && previousYears != null) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => const PasswordDialog(),
                      );

                      if (confirmed == true) {
                        if (!context.mounted) return;
                        await Provider.of<AppDataProvider>(context,
                                listen: false)
                            .updateSettings(
                          baseFineAmount: baseFine,
                          previousYearsBalance: previousYears,
                        );

                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Einstellungen wurden aktualisiert'),
                          ),
                        );
                        setState(() {
                          _hasChanges = false;
                        });
                      }
                    }
                  }
                : null,
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatefulWidget {
  const _CalendarTab();
  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    super.dispose();
    _saveEvents(); // Speichern der Events beim Verlassen des Tabs
  }

  Future<void> _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? eventsJson = prefs.getString('Termine');
    if (eventsJson != null) {
      Map<String, dynamic> decodedJson = jsonDecode(eventsJson);
      setState(() {
        _events = decodedJson.map((key, value) {
          DateTime dateKey = DateTime.parse(key);
          List<String> events = List<String>.from(value);
          return MapEntry(dateKey, events);
        });
      });
    }
  }

  Future<void> _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> eventsToSave = _events.map((key, value) {
      String dateKey = key.toIso8601String();
      return MapEntry(dateKey, value);
    });
    String eventsJson = jsonEncode(eventsToSave);
    await prefs.setString('Termine', eventsJson);
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _addEvent(String event) {
    if (_selectedDay != null) {
      setState(() {
        if (_events[_selectedDay!] == null) {
          _events[_selectedDay!] = [];
        }
        _events[_selectedDay!]!.add(event);
        _saveEvents(); // Speichern nach dem Hinzufügen eines Events
      });
    }
  }

  void _editEvent(String oldEvent) {
    TextEditingController eventController =
        TextEditingController(text: oldEvent);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termin bearbeiten'),
        content: TextField(
          controller: eventController,
          decoration: const InputDecoration(hintText: 'Termin bearbeiten'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                setState(() {
                  List<String> events = _events[_selectedDay!]!;
                  events[events.indexOf(oldEvent)] = eventController.text;
                  _saveEvents(); // Speichern nach dem Bearbeiten
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(String event) {
    // Bestätigungsdialog hinzufügen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termin löschen'),
        content:
            Text('Bist du sicher, dass du dieses Termin löschen möchtest?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Schließt den Dialog ohne zu löschen
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                List<String> events = _events[_selectedDay!]!;
                events.remove(event);
                if (events.isEmpty) {
                  _events.remove(
                      _selectedDay); // Entferne den Tag, wenn keine Events mehr vorhanden sind
                }
                _saveEvents(); // Speichern nach dem Löschen
              });
              Navigator.pop(
                  context); // Schließt den Bestätigungsdialog nach dem Löschen
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    TextEditingController eventController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Termin hinzufügen'),
        content: TextField(
          controller: eventController,
          decoration: const InputDecoration(hintText: 'Termin hier eintragen!'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              if (eventController.text.isNotEmpty) {
                _addEvent(eventController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_selectedDay != null) {
              _showAddEventDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Du musst schon ein Datum auswählen!'),
                ),
              );
            }
          },
          child: const Text('Termin hinzufügen'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: _getEventsForDay(_selectedDay ?? _focusedDay)
                .map((event) => Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(event),
                        onTap: () =>
                            _editEvent(event), // Bearbeiten eines Events
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _deleteEvent(event), // Löschen eines Events
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DataTab extends StatefulWidget {
  @override
  State<_DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<_DataTab> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datenexport/Import',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        try {
                          setState(() => _isLoading = true);
                          await appData.exportData(context);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Daten wurden erfolgreich exportiert'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fehler beim Exportieren: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                icon: const Icon(Icons.upload_file),
                label: const Text('Daten exportieren'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        try {
                          setState(() => _isLoading = true);
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                          );

                          if (result != null &&
                              result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            final jsonString = await file.readAsString();
                            await appData.importData(jsonString);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Daten wurden erfolgreich importiert'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Erzwinge einen Rebuild der gesamten App
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fehler beim Importieren: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                icon: const Icon(Icons.file_download),
                label: const Text('Daten importieren'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hinweis: Der Export erstellt eine JSON-Datei mit allen App-Daten, die Sie auf anderen Geräten importieren können.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
