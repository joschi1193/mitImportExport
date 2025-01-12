import 'package:fines_manager/providers/current_round_provider.dart';
import 'package:fines_manager/utils/fine_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fine.dart';
import '../models/attendance.dart';
import '../providers/app_data_provider.dart';
import '../widgets/overview_balance_card.dart';
import '../widgets/unpaid_fines_card.dart';
import '../widgets/fine_buttons_grid.dart';
import '../widgets/current_round_card.dart';
import '../controllers/fine_controller.dart';

class OverviewScreen extends StatefulWidget {
  final double totalBalance;
  final List<Fine> fines;
  final Function(Fine) onAddFine;
  final List<Attendance> attendance;
  final Map<String, double> overpayments;

  const OverviewScreen({
    super.key,
    required this.totalBalance,
    required this.fines,
    required this.onAddFine,
    required this.attendance,
    required this.overpayments,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late final FineController _fineController;
  Map<String, double> _unpaidTotals = {};

  @override
  void initState() {
    super.initState();
    _fineController = FineController(
      fines: widget.fines,
      attendance: widget.attendance,
      onAddFine: widget.onAddFine,
      onUpdateUnpaidTotals: _updateUnpaidTotals,
      context: context, // Hier fügen wir den context Parameter hinzu
    );
    _updateUnpaidTotals();
  }

  void _updateUnpaidTotals() {
    setState(() {
      _unpaidTotals = _fineController.calculateUnpaidTotals(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final currentRoundProvider = Provider.of<CurrentRoundProvider>(context);
    final presentPlayers = getPresentPlayers(widget.attendance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Übersicht'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            OverviewBalanceCard(
              totalBalance: widget.totalBalance,
              totalOverpayments: widget.overpayments.values.fold(
                0,
                (sum, amount) => sum + amount,
              ),
            ),
            if (_unpaidTotals.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: UnpaidFinesCard(unpaidTotals: _unpaidTotals),
              ),
            FineButtonsGrid(
              predefinedFines: appData.predefinedFines,
              onFineSelected: _fineController.handleFineButton,
            ),
            if (currentRoundProvider.hasRoundFines)
              CurrentRoundCard(
                roundFines: currentRoundProvider.roundFines,
                currentAverage: currentRoundProvider
                    .calculateCurrentAverage(presentPlayers),
                onSave: () => _fineController.saveRound(context),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
