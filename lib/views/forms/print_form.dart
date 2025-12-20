// import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintFormPage extends StatelessWidget {
  final Map<String, String> formData;

  const PrintFormPage({super.key, required this.formData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Print Membership Form')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final pdf = await generatePDF();
            await Printing.layoutPdf(onLayout: (format) => pdf.save());
          },
          child: Text('Print Form'),
        ),
      ),
    );
  }

  Future<pw.Document> generatePDF() async {
    final pdf = pw.Document();

    // Load the background image (exported from your form)
    final Uint8List bgImage = await _loadFormBackground();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Image(
                pw.MemoryImage(bgImage),
                fit: pw.BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              pw.Positioned(
                left: 50,
                top: 150,
                child: pw.Text(
                  'Form No: ${formData['formNo']}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Positioned(
                left: 50,
                top: 180,
                child: pw.Text(
                  'Name: ${formData['name']}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.Positioned(
                left: 50,
                top: 210,
                child: pw.Text(
                  'Mobile No: ${formData['mobile']}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ),
              // Add all fields here by positioning them based on your form design
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<Uint8List> _loadFormBackground() async {
    // Replace this with your background image as a Uint8List
    final ByteData bytes = await
    rootBundle.load(
      'assets/forms/membership_form.jpg',
    );
    return bytes.buffer.asUint8List();
  }
}
