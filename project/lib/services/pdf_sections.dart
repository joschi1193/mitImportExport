import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/fine.dart';
import '../../models/attendance.dart';

class PdfSections {
  static pw.Widget header(String title) {
    return pw.Header(
      level: 0,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 24,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget summary(double totalFines, double averageFine) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Zusammenfassung:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Gesamtstrafen: ${totalFines.toStringAsFixed(2)} €'),
        pw.Text('Durchschnitt: ${averageFine.toStringAsFixed(2)} €'),
      ],
    );
  }

  static pw.Widget attendanceTable(List<Attendance> attendance) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Anwesenheit:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _tableCell('Name', isHeader: true),
                _tableCell('Status', isHeader: true),
              ],
            ),
            // Data rows
            ...attendance.map((record) => pw.TableRow(
              children: [
                _tableCell(record.name),
                _tableCell(record.status.toString().split('.').last),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget finesTable(List<Fine> fines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Strafen:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _tableCell('Name', isHeader: true),
                _tableCell('Beschreibung', isHeader: true),
                _tableCell('Betrag', isHeader: true),
                _tableCell('Bezahlt', isHeader: true),
              ],
            ),
            // Data rows
            ...fines.map((fine) => pw.TableRow(
              children: [
                _tableCell(fine.name),
                _tableCell(fine.description),
                _tableCell('${fine.amount.toStringAsFixed(2)} €'),
                _tableCell(fine.isPaid ? 'Ja' : 'Nein'),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget overpaymentsTable(Map<String, double> overpayments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Überzahlungen:',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _tableCell('Name', isHeader: true),
                _tableCell('Betrag', isHeader: true),
              ],
            ),
            // Data rows
            ...overpayments.entries.map((entry) => pw.TableRow(
              children: [
                _tableCell(entry.key),
                _tableCell('${entry.value.toStringAsFixed(2)} €'),
              ],
            )),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
