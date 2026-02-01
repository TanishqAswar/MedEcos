import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndPrintPrescription({
    required String doctorName,
    required String patientName,
    required String patientId,
    required String symptoms,
    required List<Map<String, String>> medicines,
    required String date,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("MedEcos Clinic", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text("Date: $date"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Doctor & Patient Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(doctorName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Cardiologist"),
                    ],
                   ),
                   pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Patient: $patientName", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text("ID: $patientId"),
                    ],
                   ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              
              // Symptoms
              pw.Text("Diagnosis / Symptoms:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(symptoms),
              pw.SizedBox(height: 20),
              
              // Medicines Table
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                },
                data: <List<String>>[
                  ['Medicine', 'Timing', 'Context', 'Instructions'],
                  ...medicines.map((m) => [
                    m['name']!,
                    m['timing']!,
                    m['context']!,
                    m['instruction']!
                  ]),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Get well soon!", style: const pw.TextStyle(color: PdfColors.grey)),
                  pw.Column(
                    children: [
                       pw.SizedBox(height: 40),
                       pw.Text("Doctor's Signature", style: const pw.TextStyle(decoration: pw.TextDecoration.overline)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Prescription_$patientId.pdf',
    );
  }
}
