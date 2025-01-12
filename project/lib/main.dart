import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/overview_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/fines_table_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/fine_statistics_screen.dart';
import 'models/fine.dart';
import 'models/payment.dart';
import 'models/attendance.dart';
import 'services/storage_service.dart';
import 'providers/app_data_provider.dart';
import 'providers/current_round_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.create();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AppDataProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (context) => CurrentRoundProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schocken',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MainScreen(
          storageService: Provider.of<AppDataProvider>(context).storageService),
    );
  }
}

class MainScreen extends StatefulWidget {
  final StorageService storageService;

  const MainScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  List<Fine> fines = [];
  List<Payment> payments = [];
  List<Attendance> attendance = [];
  double totalBalance = 0;
  Map<String, double> overpayments = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveData();
    }
  }

  Future<void> _loadData() async {
    final loadedFines = await widget.storageService.loadFines();
    final loadedAttendance = await widget.storageService.loadAttendance();
    final loadedOverpayments = await widget.storageService.loadOverpayments();

    setState(() {
      fines = loadedFines;
      attendance = loadedAttendance;
      overpayments = loadedOverpayments;
      _calculateTotalBalance();
    });
  }

  Future<void> _saveData() async {
    await widget.storageService.saveFines(fines);
    await widget.storageService.saveAttendance(attendance);
    await widget.storageService.saveOverpayments(overpayments);
  }

  void _calculateTotalBalance() {
    double total = 0;

    for (final fine in fines) {
      if (fine.isPaid) {
        total += fine.amount;
      }
    }

    setState(() {
      totalBalance = total;
    });
  }

  void _onAddFine(Fine fine) async {
    setState(() {
      fines.add(fine);
      _calculateTotalBalance();
    });
    await widget.storageService.saveFines(fines);
  }

  void _onAddAttendance(List<Attendance> newAttendance) async {
    setState(() {
      attendance.addAll(newAttendance);
    });
    await widget.storageService.saveAttendance(attendance);
  }

  void _onPayment(String name, double amount) async {
    final unpaidFines = fines
        .where((fine) => fine.name == name && !fine.isPaid)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double remainingAmount = amount;

    for (final fine in unpaidFines) {
      if (remainingAmount >= fine.amount) {
        fine.isPaid = true;
        remainingAmount -= fine.amount;
      } else {
        break;
      }
    }

    if (remainingAmount > 0) {
      setState(() {
        overpayments[name] = (overpayments[name] ?? 0) + remainingAmount;
      });
      await widget.storageService.saveOverpayments(overpayments);
    }

    setState(() {
      _calculateTotalBalance();
    });
    await widget.storageService.saveFines(fines);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      OverviewScreen(
        totalBalance: totalBalance,
        fines: fines,
        onAddFine: _onAddFine,
        attendance: attendance,
        overpayments: overpayments,
      ),
      AttendanceScreen(
        onAddFines: (newFines) {
          for (final fine in newFines) {
            _onAddFine(fine);
          }
        },
        onSaveAttendance: _onAddAttendance,
      ),
      FinesTableScreen(
        fines: fines,
        onPayment: _onPayment,
        onUpdateFine: (fine) async {
          setState(() {
            final index = fines.indexWhere((f) =>
                f.name == fine.name &&
                f.date == fine.date &&
                f.description == fine.description);
            if (index != -1) {
              fines[index] = fine;
            }
          });
          await widget.storageService.saveFines(fines);
        },
      ),
      HistoryScreen(
        fines: fines,
        attendance: attendance,
        overpayments: overpayments,
      ),
      FineStatisticsScreen(fines: fines),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Übersicht',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Anwesenheit',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart),
            label: 'Strafenliste',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Historie',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Optionen',
          ),
        ],
      ),
    );
  }
}
