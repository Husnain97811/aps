import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

class PdfGenerationService {
  static Future<File> generateInstallmentPdf(
    Map<String, dynamic> installment,
  ) async {
    // Load assets
    final reliableImageBytes = await rootBundle.load(
      'assets/images/logo_reliable.png',
    );
    final reliableLogo = pw.MemoryImage(
      reliableImageBytes.buffer.asUint8List(),
    );

    final apldImageBytes = await rootBundle.load('assets/images/apld_logo.png');
    final apldLogo = pw.MemoryImage(apldImageBytes.buffer.asUint8List());

    final materialIconsFont = await rootBundle.load(
      'assets/fonts/MaterialIcons-Regular.ttf',
    );
    final materialIcons = pw.Font.ttf(materialIconsFont);

    // Determine payment category
    String category;
    final paymentDescription =
        installment['description']?.toString().toLowerCase() ?? '';
    if (paymentDescription == 'cash') {
      category = 'All Dues Cleared';
    } else if (paymentDescription == 'hy installment') {
      category = 'H.Y Installment';
    } else if (paymentDescription == 'simple installment') {
      category = 'Installment';
    } else if (paymentDescription == 'development charges') {
      category = 'Development Charges';
    } else {
      category = paymentDescription;
    }

    // Format date
    String formattedDate = installment['date'] ?? 'N/A';
    try {
      final date = DateTime.parse(installment['date']);
      formattedDate = DateFormat('yyyy-MMM-dd').format(date);
    } catch (_) {}

    // Check if it's late installments offer
    final isLateInstallmentsOffer = installment['special_offer'] == true;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.SizedBox(width: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Image(reliableLogo, width: 73, height: 73),
                  pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Align(
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'Reliable Marketing Network',
                              style: pw.TextStyle(
                                fontSize: 18.8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                          pw.Container(
                            height: 17,
                            child: pw.Align(
                              alignment: pw.Alignment.bottomRight,
                              child: pw.Text(
                                'Pvt ltd',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3.5),
                      pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'Installment Slip',
                          style: pw.TextStyle(
                            fontSize: 12.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Image(
                    alignment: pw.Alignment.bottomRight,
                    apldLogo,
                    width: 63,
                    height: 63,
                  ),
                ],
              ),
              pw.SizedBox(width: 48),
              pw.Container(
                decoration: pw.BoxDecoration(),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: _buildLabeledField(
                            'Receipt No',
                            installment['receipt_no']?.toString() ?? 'N/A',
                            150,
                          ),
                        ),
                        pw.SizedBox(width: 40),
                        pw.Expanded(
                          child: _buildLabeledField('Date', formattedDate, 150),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 30),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 1,
                          child: _buildLabeledField(
                            'Membership No',
                            (installment['membership_no']?.toString() ?? 'N/A')
                                .toUpperCase(),
                            150,
                          ),
                        ),
                        pw.SizedBox(width: 40),
                        pw.Expanded(
                          flex: 1,
                          child: _buildLabeledField(
                            'Inst No',
                            installment['installment_no']?.toString() ?? 'N/A',
                            150,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 28),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text(
                            'Received with Thanks',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Container(
                            width: 260,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  style: pw.BorderStyle(pattern: [2, 2, 2]),
                                ),
                              ),
                            ),
                            child: pw.Padding(
                              padding: pw.EdgeInsets.only(bottom: 0.1.h),
                              child: pw.Text(
                                '${(installment['name'] ?? '').split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ')} S/O ${(installment['father_husband_name'] ?? '').split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ')}',
                                style: pw.TextStyle(fontSize: 12),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 35),
                    pw.Container(
                      alignment: pw.Alignment.centerLeft,
                      width: double.infinity,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          _buildBoxField(
                            'CNIC ',
                            installment['cnic']?.toString() ?? '',
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 35),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 1,
                          child: _buildUnderlineLabeledField(
                            'Phone',
                            installment['mobile_no']?.toString() ?? 'N/A',
                            210,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          flex: 1,
                          child: _buildUnderlineLabeledField(
                            'Project',
                            'Al-Imran Garden',
                            210,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 30),

                    // Check if it's late installments offer
                    if (isLateInstallmentsOffer)
                      // Show Offer Amount Fields
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: _buildBoxCashField(
                              'Offer Amount ',
                              installment['offer_received_amount']
                                      ?.toString() ??
                                  'N/A',
                              137,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          installment['offer_discount_amount'] != null &&
                                  installment['offer_discount_amount']
                                      .toString()
                                      .isNotEmpty
                              ? pw.Expanded(
                                flex: 1,
                                child: _buildBoxCashField(
                                  'Offer Discount ',
                                  installment['offer_discount_amount']
                                          ?.toString() ??
                                      'N/A',
                                  137,
                                ),
                              )
                              : pw.Expanded(flex: 1, child: pw.Container()),
                        ],
                      )
                    else
                      // Show Regular Amount Fields
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: _buildBoxCashField(
                              'Amount ',
                              installment['received_amount']?.toString() ??
                                  'N/A',
                              137,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          installment['discount'] != null &&
                                  installment['discount'].toString().isNotEmpty
                              ? pw.Expanded(
                                flex: 1,
                                child: _buildBoxCashField(
                                  'Discount ',
                                  installment['discount']?.toString() ?? 'N/A',
                                  137,
                                ),
                              )
                              : pw.Expanded(flex: 1, child: pw.Container()),
                        ],
                      ),

                    pw.SizedBox(height: 28),

                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 1,
                          child: _buildAmountInWordsUnderlineLabeledField(
                            'Amount in Words',
                            (installment['amount_in_words']?.toString() ??
                                    'N/A')
                                .split(' ') // Split into words
                                .map(
                                  (word) =>
                                      word.isNotEmpty
                                          ? word[0].toUpperCase() +
                                              word.substring(1).toLowerCase()
                                          : word,
                                ) // Capitalize first letter, lowercase others
                                .join(' '), // Join back into a single string
                            150,
                          ),
                        ),
                        pw.SizedBox(width: 20),
                        pw.Expanded(
                          flex: 1,
                          child: _buildLabeledField(
                            'Transaction Type',
                            (installment['mode_of_payment']?.toString() ??
                                    'N/A')
                                .split(' ')
                                .map(
                                  (word) =>
                                      word[0].toUpperCase() +
                                      word.substring(1).toLowerCase(),
                                )
                                .join(' '),
                            137,
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 28),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // pw.SizedBox(width: 20),
                        pw.Expanded(
                          flex: 1,
                          child: _buildLabeledField(
                            'Payment Category',
                            category,
                            140,
                          ),
                        ),
                        pw.SizedBox(width: 20),

                        pw.Expanded(
                          flex: 1,
                          child: _buildLabeledField(
                            'Generated By',
                            (installment['authorized_signature']?.toString() ??
                                    'N/A')
                                .split(' ')
                                .take(2) // Take only first two words
                                .map(
                                  (word) =>
                                      word.isNotEmpty
                                          ? word[0].toUpperCase() +
                                              word.substring(1).toLowerCase()
                                          : '',
                                )
                                .join(' '),
                            137,
                            fontsize: 8,
                            fontstyle: pw.FontStyle.italic,
                            padding: pw.EdgeInsets.all(0.2.h),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 28),
                    // pw.Row(
                    //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    //   children: [

                    //     pw.SizedBox(width: 20),
                    //     pw.Expanded(
                    //       flex: 1,
                    //       child: _buildLabeledFieldforSignature(
                    //         '',
                    //         category,
                    //         140,
                    //         PdfColors.white,
                    //         PdfColors.white,
                    //         PdfColors.white,
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    // pw.SizedBox(height: 28),
                    installment['remarks'] != null &&
                            installment['remarks'].toString().isNotEmpty
                        ? pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              flex: 1,
                              child: pw.Text(
                                'Remarks',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Expanded(
                              flex: 4,
                              child: pw.Container(
                                width: 260,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(),
                                ),
                                child: pw.Padding(
                                  padding: pw.EdgeInsets.only(bottom: 0.1.h),
                                  child: pw.Text(
                                    maxLines: 2,
                                    installment['remarks'].toString(),
                                    style: pw.TextStyle(fontSize: 12),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : pw.Container(),

                    pw.SizedBox(height: 130),
                    pw.Container(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            alignment: pw.Alignment.center,
                            width: 150,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                  style: pw.BorderStyle(pattern: [2, 2, 2]),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          pw.Text(
                            'Authorized Sign.',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 50),
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Head Office',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Text(
                          textAlign: pw.TextAlign.center,
                          'Office, 2nd Floor, Plaza #33, Mini Commercial Extension #01\nBahria Town Phase # 07, Rwp',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Footer(
                leading: pw.Row(
                  children: [
                    pw.Text(
                      String.fromCharCode(0xe158), // Email icon
                      style: pw.TextStyle(font: materialIcons, fontSize: 15),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      'reliablemarketingnetwork@gmail.com',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                title: pw.Row(
                  children: [
                    pw.Text(
                      String.fromCharCode(0xe80b), // Website icon
                      style: pw.TextStyle(font: materialIcons, fontSize: 15),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      'www.reliablemarketingnetwork.com',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: pw.Row(
                  children: [
                    pw.Text(
                      String.fromCharCode(0xe0cd), // Phone icon
                      style: pw.TextStyle(
                        font: materialIcons,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '051 2000774',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to file
    final directory = await getDownloadsDirectory();
    final safeReceiptNo =
        installment['receipt_no']?.toString().replaceAll(
          RegExp(r'[\/:*?"<>|]'),
          '_',
        ) ??
        'receipt';
    final file = File('${directory!.path}/$safeReceiptNo.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Helper methods for PDF widgets
  static pw.Widget _buildLabeledField(
    String label,
    String value,
    double width, {

    ///add font size optional
    double? fontsize,
    //add fontstyle optional
    pw.FontStyle? fontstyle,
    pw.EdgeInsets? padding,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Padding(
            padding: padding ?? pw.EdgeInsets.only(bottom: 0.1.h),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: fontsize ?? 12,
                fontStyle: fontstyle ?? pw.FontStyle.normal,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLabeledFieldforSignature(
    String label,
    String value,
    double width,
    PdfColor labelColor,
    PdfColor valueColor,
    PdfColor borderColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: labelColor,
          ),
        ),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor),
          ),
          child: pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 0.1.h),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12, color: valueColor),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildUnderlineLabeledField(
    String label,
    String value,
    double width,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(style: pw.BorderStyle(pattern: [2, 2])),
            ),
          ),
          child: pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 0.1.h),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAmountInWordsUnderlineLabeledField(
    String label,
    String value,
    double width,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(style: pw.BorderStyle(pattern: [2, 2])),
            ),
          ),
          child: pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 0.1.h),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8, wordSpacing: 1),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBoxCashField(
    String label,
    String value,
    double width,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Padding(
            padding: pw.EdgeInsets.only(bottom: 0.1.h),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11.5),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBoxField(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
        ),
        pw.SizedBox(height: 0.5.h),
        pw.Container(
          width: 286,
          child: pw.Expanded(
            child: pw.Row(
              children:
                  List.generate(
                    13,
                    (index) => pw.Padding(
                      padding: pw.EdgeInsets.only(right: 0.2.w),
                      child: pw.Container(
                        width: 18.2,
                        height: 21,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1.3,
                          ),
                        ),
                        child: pw.Text(
                          index < value.length ? value[index] : '',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
