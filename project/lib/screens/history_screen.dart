import 'package:fines_manager/models/export_format.dart';
import 'package:fines_manager/services/pdf_export_service.dart';
import 'package:flutter/material.dart';
import '../models/fine.dart';
import '../models/attendance.dart';
import '../widgets/history_attendance_list.dart';
import '../widgets/history_fines_list.dart';
import '../widgets/history_overpayments_list.dart';
import '../services/xml_export_service.dart';
import '../services/file_export_service.dart';
import '../dialogs/export_format_dialog.dart';
import '../utils/date_utils.dart';

class HistoryScreen extends StatelessWidget {
  final List<Fine> fines;
  final List<Attendance> attendance;
  final Map<String, double> overpayments;
  final _xmlExportService = XmlExportService();
  final _pdfExportService = PdfExportService();
  final _fileExportService = FileExportService();

  HistoryScreen({
    super.key,
    required this.fines,
    required this.attendance,
    required this.overpayments,
  });

  Future<void> _exportDay(
      BuildContext context, String dateKey, List<dynamic> items) async {
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => const ExportFormatDialog(),
    );

    if (format == null) return;

    final dayFines = items.whereType<Fine>().toList();
    final dayAttendance = items.whereType<Attendance>().toList();

    switch (format) {
      case ExportFormat.xml:
        final xmlContent = _xmlExportService.generateDayXml(
          date: dateKey,
          fines: dayFines,
          attendance: dayAttendance,
          overpayments: overpayments,
        );
        await _fileExportService.exportAndShare(
          xmlContent,
          'strafenkasse_$dateKey.xml',
        );
        break;

      case ExportFormat.pdf:
        await _pdfExportService.generateDayPdf(
          date: dateKey,
          fines: dayFines,
          attendance: dayAttendance,
          overpayments: overpayments,
        );
        break;
    }
  }

  Future<void> _exportOverpayments(BuildContext context) async {
    if (overpayments.isEmpty) return;

    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => const ExportFormatDialog(),
    );

    if (format == null) return;

    final date = formatDate(DateTime.now());

    switch (format) {
      case ExportFormat.xml:
        final xmlContent =
            _xmlExportService.generateOverpaymentsXml(overpayments);
        await _fileExportService.exportAndShare(
          xmlContent,
          'strafenkasse_ueberzahlungen_$date.xml',
        );
        break;

      case ExportFormat.pdf:
        await _pdfExportService.generateOverpaymentsPdf(overpayments);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _xmlExportService.groupItemsByDate(fines, attendance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historie'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          if (overpayments.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: HistoryOverpaymentsList(overpayments: overpayments),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dateKey = groupedItems.keys.elementAt(index);
                final items = groupedItems[dateKey]!;
                final dayFines = items.whereType<Fine>().toList();
                final dayAttendance = items.whereType<Attendance>().toList();
                final totalAmount = dayFines.fold<double>(
                  0,
                  (sum, fine) => sum + fine.amount,
                );

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                              '$dateKey - Gesamt: ${totalAmount.toStringAsFixed(2)} €'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _exportDay(context, dateKey, items),
                          tooltip: 'Tag exportieren',
                        ),
                      ],
                    ),
                    children: [
                      if (dayAttendance.isNotEmpty)
                        HistoryAttendanceList(attendance: dayAttendance),
                      if (dayFines.isNotEmpty)
                        HistoryFinesList(fines: dayFines),
                    ],
                  ),
                );
              },
              childCount: groupedItems.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: overpayments.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _exportOverpayments(context),
              child: const Icon(Icons.payments),
              tooltip: 'Überzahlungen exportieren',
            )
          : null,
    );
  }
}
