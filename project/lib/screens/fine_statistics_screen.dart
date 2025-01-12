import 'package:fines_manager/services/pdf_export_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fine.dart';
import '../providers/app_data_provider.dart';

class FineStatisticsScreen extends StatelessWidget {
  final List<Fine> fines;
  final _pdfExportService = PdfExportService();

  FineStatisticsScreen({
    super.key,
    required this.fines,
  });

  Map<String, Map<String, int>> _calculateStatistics(
      List<Fine> fines, List<String> names) {
    final statistics = <String, Map<String, int>>{};

    // Initialize statistics map for all names
    for (final name in names) {
      statistics[name] = {};
    }

    // Count fines for each person, excluding specific types
    for (final fine in fines) {
      // Skip specific fine types we want to exclude
      if (fine.description.contains('Durchschnitt') ||
          fine.description.contains('Grundbetrag')) {
        continue;
      }

      if (!statistics.containsKey(fine.name)) {
        statistics[fine.name] = {};
      }

      final personStats = statistics[fine.name]!;
      personStats[fine.description] = (personStats[fine.description] ?? 0) + 1;
    }

    return statistics;
  }

  List<String> _getAllFineTypes(Map<String, Map<String, int>> statistics) {
    final fineTypes = <String>{};

    for (final personStats in statistics.values) {
      fineTypes.addAll(personStats.keys);
    }

    return fineTypes.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppDataProvider>(context);
    final statistics = _calculateStatistics(fines, appData.names);
    final fineTypes = _getAllFineTypes(statistics);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Strafenstatistik'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _pdfExportService.exportStatistics(
              statistics: statistics,
              fineTypes: fineTypes,
            ),
            tooltip: 'Als PDF exportieren',
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              const DataColumn(
                label: Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...fineTypes.map((type) => DataColumn(
                    label: Tooltip(
                      message: type,
                      child: SizedBox(
                        width: 80,
                        child: Text(
                          type,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )),
            ],
            rows: statistics.entries.map((entry) {
              final name = entry.key;
              final personStats = entry.value;

              return DataRow(
                cells: [
                  DataCell(Text(name)),
                  ...fineTypes.map((type) => DataCell(
                        Text(
                          (personStats[type] ?? 0).toString(),
                          textAlign: TextAlign.center,
                        ),
                      )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
