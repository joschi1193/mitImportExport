import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/fine.dart';
import '../../models/attendance.dart';
import '../../utils/date_utils.dart';
import 'pdf_sections.dart';

class PdfExportService {
  Future<void> exportStatistics({
    required Map<String, Map<String, int>> statistics,
    required List<String> fineTypes,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Strafenstatistik',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          _buildStatisticsTable(statistics, fineTypes),
          pw.SizedBox(height: 20),
          pw.Footer(
            title: pw.Text(
              'Erstellt am ${formatDate(now)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/strafenstatistik_${now.millisecondsSinceEpoch}.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> generateDayPdf({
    required String date,
    required List<Fine> fines,
    required List<Attendance> attendance,
    required Map<String, double> overpayments,
  }) async {
    final pdf = pw.Document();
    final totalFines = fines.fold<double>(0, (sum, fine) => sum + fine.amount);
    final averageFine = _calculateAverageFine(fines, attendance);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          PdfSections.header('Strafenkasse - $date'),
          pw.SizedBox(height: 20),
          PdfSections.summary(totalFines, averageFine),
          pw.SizedBox(height: 20),
          if (attendance.isNotEmpty) ...[
            PdfSections.attendanceTable(attendance),
            pw.SizedBox(height: 20),
          ],
          if (fines.isNotEmpty) ...[
            PdfSections.finesTable(fines),
            pw.SizedBox(height: 20),
          ],
          if (overpayments.isNotEmpty)
            PdfSections.overpaymentsTable(overpayments),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/strafenkasse_$date.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> generateOverpaymentsPdf(Map<String, double> overpayments) async {
    final pdf = pw.Document();
    final date = formatDate(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfSections.header('Überzahlungen'),
            pw.SizedBox(height: 20),
            PdfSections.overpaymentsTable(overpayments),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/ueberzahlungen_$date.pdf',
    );

    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  pw.Table _buildStatisticsTable(
    Map<String, Map<String, int>> statistics,
    List<String> fineTypes,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          children: [
            _tableCell('Name', isHeader: true),
            ...fineTypes.map((type) => _tableCell(type, isHeader: true)),
          ],
        ),
        ...statistics.entries.map((entry) {
          final name = entry.key;
          final personStats = entry.value;

          return pw.TableRow(
            children: [
              _tableCell(name),
              ...fineTypes.map((type) => _tableCell(
                    (personStats[type] ?? 0).toString(),
                    align: pw.TextAlign.center,
                  )),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: align,
      ),
    );
  }

  double _calculateAverageFine(List<Fine> fines, List<Attendance> attendance) {
    final presentCount =
        attendance.where((a) => a.status != AttendanceStatus.absent).length;

    if (presentCount == 0) return 0;

    final totalFines = fines
        .where((f) => !f.description.contains('Grundbetrag'))
        .fold<double>(0, (sum, fine) => sum + fine.amount);

    return totalFines / presentCount;
  }
}
