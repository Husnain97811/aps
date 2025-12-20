import 'dart:io';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsRefundProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allClients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  String _activeFilter = 'suspended';
  String _searchQuery = '';
  bool _isLoading = false;
  Map<String, dynamic>? _selectedClient;

  List<Map<String, dynamic>> get filteredClients => _filteredClients;
  String get activeFilter => _activeFilter;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get selectedClient => _selectedClient;

  ClientsRefundProvider() {
    fetchRefundClients();
  }

  void selectClient(Map<String, dynamic> client) {
    _selectedClient = client;
    notifyListeners();
  }

  void clearSelectedClient() {
    _selectedClient = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchClientByMembershipNo(
    String membershipNo,
  ) async {
    try {
      final response =
          await _supabase
              .from('membership_forms')
              .select()
              .eq('membership_no', membershipNo)
              .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchRefundDetails(String membershipNo) async {
    try {
      final response =
          await _supabase
              .from('refunds')
              .select()
              .eq('membership_no', membershipNo)
              .order('created_at', ascending: false)
              .limit(1)
              .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> generateRefundStatementPDF(BuildContext context) async {
    if (_selectedClient == null) return;

    try {
      final loadingProvider = context.read<LoadingProvider>();
      loadingProvider.startPdfLoading();

      final membershipNo = _selectedClient!['membership_no']?.toString();
      final client = _selectedClient!;

      final refundResponse =
          await _supabase
              .from('refunds')
              .select()
              .eq('membership_no', membershipNo.toString())
              .order('created_at', ascending: false)
              .limit(1)
              .single();
      final refund = refundResponse;

      // Fetch paid receipts and order by creation date (CORRECTED)
      final paidReceiptsResponse = await _supabase
          .from('refund_receipts')
          .select()
          .eq('membership_no', membershipNo.toString())
          .order('generated_date', ascending: true);
      final List<Map<String, dynamic>> paidReceipts = List.from(
        paidReceiptsResponse,
      );

      final pdf = pw.Document();
      final apldLogo = pw.MemoryImage(
        (await rootBundle.load(
          'assets/images/apld_logo.png',
        )).buffer.asUint8List(),
      );
      final reliableLogo = pw.MemoryImage(
        (await rootBundle.load(
          'assets/images/logo_reliable.png',
        )).buffer.asUint8List(),
      );

      final totalPaid = (refund['total_paid'] as num).toDouble();
      final refundAmount = (refund['refund_amount'] as num).toDouble();
      final installments = refund['installments'] as int;
      final periodMonths = refund['period_months'] as int;
      final interval = installments > 0 ? periodMonths ~/ installments : 0;
      const baseFontSize = 10.0;
      final reducedFontSize = baseFontSize * 0.8;

      final List<pw.TableRow> scheduleRows = _generateRefundScheduleRows(
        refund,
        paidReceipts,
        reducedFontSize,
      );

      pdf.addPage(
        pw.MultiPage(
          build:
              (context) => [
                // Header Section
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(reliableLogo, width: 80, height: 80),
                      pw.Column(
                        children: [
                          pw.Text(
                            'AL-IMRAN GARDEN',
                            style: pw.TextStyle(
                              fontSize: reducedFontSize * 1.7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Refund Statement',
                            style: pw.TextStyle(
                              fontSize: reducedFontSize * 1.2,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Image(apldLogo, width: 70, height: 70),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Member Information
                pw.Header(
                  text: 'Member Information',
                  textStyle: pw.TextStyle(
                    fontSize: reducedFontSize * 1.2,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Container(
                  width: 500,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Membership No:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'CNIC:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Name:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Mobile No:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(width: 80),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                client['membership_no']
                                        ?.toString()
                                        .toUpperCase() ??
                                    'N/A',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                client['cnic_passport_no']?.toString() ?? 'N/A',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                client['name']?.toString().toUpperCase() ??
                                    'N/A',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                client['mobile_no']?.toString() ?? 'N/A',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Align(
                        alignment: pw.Alignment.topRight,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 10),
                          child: pw.Row(
                            children: [
                              pw.Text(
                                'Print Date:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(width: 5),
                              pw.Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Refund Details
                pw.Header(
                  text: 'Refund Details',
                  textStyle: pw.TextStyle(
                    fontSize: reducedFontSize * 1.2,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Total Paid:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Refund Amount:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                NumberFormat.currency(
                                  symbol: '',
                                ).format(totalPaid),
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                NumberFormat.currency(
                                  symbol: '',
                                ).format(refundAmount),
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Installments:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'Refund Period:',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                '$installments',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                periodMonths >= 12
                                    ? '${(periodMonths / 12).toStringAsFixed(periodMonths % 12 == 0 ? 0 : 1)} year${periodMonths >= 24 ? 's' : ''}'
                                    : '$periodMonths months',
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Payment Schedule: The refund amount will be paid in $installments installments '
                  'over $periodMonths months, i.e., every $interval months.',
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 20),

                // Refund Receipts Schedule Table
                pw.Header(
                  text: 'Refund Receipts Schedule',
                  textStyle: pw.TextStyle(
                    fontSize: reducedFontSize * 1.2,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Table(
                  border: pw.TableBorder.all(),
                  // UPDATED: Column widths for the new "Paid Amount" column
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1), // Inst. No.
                    1: const pw.FlexColumnWidth(2), // Due Date
                    2: const pw.FlexColumnWidth(2), // Due Amount
                    3: const pw.FlexColumnWidth(1.5), // Status
                    4: const pw.FlexColumnWidth(2), // Paid Date
                    5: const pw.FlexColumnWidth(2), // Paid Amount (NEW)
                    6: const pw.FlexColumnWidth(3), // Receipt No.
                  },
                  children: [
                    // UPDATED: Header row with the new "Paid Amount" column
                    pw.TableRow(
                      children: [
                        _buildTableHeaderCell('Inst. No', reducedFontSize),
                        _buildTableHeaderCell('Due Date', reducedFontSize),
                        _buildTableHeaderCell('Amount', reducedFontSize),
                        _buildTableHeaderCell('Status', reducedFontSize),
                        _buildTableHeaderCell('Paid Date', reducedFontSize),
                        _buildTableHeaderCell('Paid Amount', reducedFontSize),
                        _buildTableHeaderCell('Receipt No.', reducedFontSize),
                      ],
                    ),
                    ...scheduleRows,
                  ],
                ),
              ],
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final filePath = '${output.path}/refund_statement_${membershipNo}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(filePath);

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Refund statement generated successfully!',
      );
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      context.read<LoadingProvider>().stopPdfLoading();
    }
  }

  // UPDATED HELPER FUNCTION TO GENERATE TABLE ROWS
  List<pw.TableRow> _generateRefundScheduleRows(
    Map<String, dynamic> refundData,
    List<Map<String, dynamic>> paidReceipts,
    double fontSize,
  ) {
    final List<pw.TableRow> rows = [];
    final refundAmount = (refundData['refund_amount'] as num).toDouble();
    final installments = refundData['installments'] as int;
    final periodMonths = refundData['period_months'] as int;

    if (installments <= 0) return [];

    final amountPerInstallment = refundAmount / installments;
    final intervalMonths = periodMonths ~/ installments;

    final refundStartDate = DateTime.parse(refundData['created_at']);
    DateTime currentDueDate = refundStartDate;

    for (int i = 0; i < installments; i++) {
      if (i > 0) {
        currentDueDate = DateTime(
          currentDueDate.year,
          currentDueDate.month + intervalMonths,
          currentDueDate.day,
        );
      }

      final bool isPaid = i < paidReceipts.length;
      final status = isPaid ? 'Paid' : 'Pending';
      final paidReceipt = isPaid ? paidReceipts[i] : null;

      // Corrected to use 'created_at' which is the standard Supabase timestamp
      final paidDate =
          paidReceipt != null && paidReceipt['generated_date'] != null
              ? DateFormat(
                'dd/MM/yyyy',
              ).format(DateTime.parse(paidReceipt['generated_date']))
              : '---';

      // NEW: Get the actual paid amount from the receipt, or '---' if not paid
      final paidAmount =
          paidReceipt != null && paidReceipt['refund_amount'] != null
              ? NumberFormat("#,##0").format(paidReceipt['refund_amount'])
              : '---';

      final receiptNo = paidReceipt?['receipt_no']?.toString() ?? '---';

      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell((i + 1).toString(), fontSize, false),
            _buildTableCell(
              DateFormat('dd/MM/yyyy').format(currentDueDate),
              fontSize,
              false,
            ),
            _buildTableCell(
              NumberFormat("#,##0").format(amountPerInstallment),
              fontSize,
              false,
            ),
            _buildTableCell(
              status,
              fontSize,
              false,
              color: isPaid ? PdfColors.green : PdfColors.orange,
            ),
            _buildTableCell(paidDate, fontSize, false),
            _buildTableCell(
              paidAmount,
              fontSize,
              false,
            ), // Added paid amount cell
            _buildTableCell(receiptNo, fontSize, false),
          ],
        ),
      );
    }
    return rows;
  }

  // region Other Methods (No Changes Below This Line)

  pw.Widget _buildTableCell(
    String text,
    double fontSize,
    bool isBold, {
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Future<void> generateRefundSlipPDF({
    required BuildContext context,
    required Map<String, dynamic> client,
    required Map<String, dynamic> refund,
    required double receiptAmount,
  }) async {
    try {
      final loadingProvider = context.read<LoadingProvider>();
      loadingProvider.startPdfLoading();

      final membershipNo = client['membership_no']?.toString();
      final now = DateTime.now();
      final formattedDate = DateFormat('dd/MM/yyyy').format(now);
      final receiptNo = 'REF-${now.millisecondsSinceEpoch}';
      final installments = refund['installments'] as int;
      final periodMonths = refund['period_months'] as int;
      final interval = periodMonths ~/ installments;
      final reason = refund['reason'] as String;

      // NEW: Get existing receipts to determine next installment number
      final existingReceipts = await _supabase
          .from('refund_receipts')
          .select()
          .eq('membership_no', membershipNo!);

      final int nextInstallmentNo = existingReceipts.length + 1;

      final pdf = pw.Document();
      final reliableLogo = pw.MemoryImage(
        (await rootBundle.load(
          'assets/images/logo_reliable.png',
        )).buffer.asUint8List(),
      );
      final apldLogo = pw.MemoryImage(
        (await rootBundle.load(
          'assets/images/apld_logo.png',
        )).buffer.asUint8List(),
      );

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
                            'Refund Slip',
                            style: pw.TextStyle(
                              fontSize: 12.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.Image(apldLogo, width: 63, height: 63),
                  ],
                ),
                pw.SizedBox(width: 48),
                pw.Container(
                  decoration: const pw.BoxDecoration(),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: _buildLabeledField(
                              'Receipt No',
                              receiptNo,
                              150,
                            ),
                          ),
                          pw.SizedBox(width: 40),
                          pw.Expanded(
                            child: _buildLabeledField(
                              'Date',
                              formattedDate,
                              150,
                            ),
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
                              membershipNo!.toUpperCase(),
                              150,
                            ),
                          ),
                          pw.SizedBox(width: 40),
                          pw.Expanded(
                            flex: 1,
                            child: _buildLabeledField(
                              'Refund Type',
                              reason == 'accidental' ? 'Accidental' : 'Normal',
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
                              'Refund Issued To',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
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
                                    style: pw.BorderStyle.dashed,
                                  ),
                                ),
                              ),
                              child: pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  client['name']?.toString().toUpperCase() ??
                                      'N/A',
                                  style: const pw.TextStyle(fontSize: 12),
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
                              client['cnic_passport_no']?.toString() ?? '',
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
                              'Project',
                              'Al-Imran Garden',
                              210,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            flex: 1,
                            child: _buildUnderlineLabeledField(
                              'Plot No',
                              client['plot_no']?.toString() ?? 'N/A',
                              210,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 30),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            flex: 1,
                            child: _buildBoxCashField(
                              'Refund Amount ',
                              receiptAmount.toStringAsFixed(0),
                              137,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            flex: 1,
                            child: _buildAmountInWordsUnderlineLabeledField(
                              'Amount in Words',
                              _amountToWords(receiptAmount),
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
                            child: _buildLabeledField(
                              'Installments',
                              '$installments',
                              137,
                            ),
                          ),
                          pw.SizedBox(width: 20),
                          pw.Expanded(
                            flex: 1,
                            child: _buildLabeledField(
                              'Installment No.',
                              '$nextInstallmentNo', // UPDATED
                              140,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 130),
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 150,
                              decoration: pw.BoxDecoration(
                                border: pw.Border(
                                  bottom: pw.BorderSide(width: 1),
                                ),
                              ),
                            ),
                            pw.Text(
                              'Authorized Sign.',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 100),
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
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Office, 2nd Floor, Plaza #33, Mini Commercial Extension #01\nBahria Town Phase # 07, Rwp',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Footer(
                  leading: pw.Row(
                    children: [
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

      final output = await getApplicationDocumentsDirectory();
      final filePath = '${output.path}/refund_slip_$receiptNo.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(filePath);

      await _supabase.from('refund_receipts').insert({
        'membership_no': membershipNo,
        'receipt_no': receiptNo,
        'refund_amount': receiptAmount,
      });

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Refund slip generated successfully!',
      );
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      context.read<LoadingProvider>().stopPdfLoading();
    }
  }

  pw.Widget _buildLabeledField(String label, String value, double width) {
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
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildUnderlineLabeledField(
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
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide()),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAmountInWordsUnderlineLabeledField(
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
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide()),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8, wordSpacing: 1),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBoxCashField(String label, String value, double width) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildBoxField(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(width: 10),
        pw.SizedBox(
          width: 286,
          child: pw.Row(
            children:
                List.generate(
                  13,
                  (index) => pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 2),
                    child: pw.Container(
                      width: 18,
                      height: 21,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
                      child: pw.Text(
                        index < value.length ? value[index] : '',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ).toList(),
          ),
        ),
      ],
    );
  }

  String _amountToWords(double amount) {
    return ' ${NumberFormat("#,##0").format(amount)} PKR Only/-';
  }

  pw.Widget _buildTableHeaderCell(String text, double fontSize) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<void> fetchRefundClients() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('membership_forms')
          .select()
          .eq('suspended', true);
      _allClients = List<Map<String, dynamic>>.from(response);
      _applyFiltersAndSearch();
    } catch (e) {
      _allClients = [];
      _filteredClients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFilter(String filter) {
    _activeFilter = filter;
    _applyFiltersAndSearch();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSearch();
  }

  void _applyFiltersAndSearch() {
    List<Map<String, dynamic>> tempClients = _allClients;
    if (_activeFilter == 'suspended') {
      tempClients =
          tempClients.where((client) => client['refunded'] != true).toList();
    } else if (_activeFilter == 'refunded') {
      tempClients =
          tempClients.where((client) => client['refunded'] == true).toList();
    }
    if (_searchQuery.isNotEmpty) {
      tempClients =
          tempClients.where((client) {
            final name = client['name']?.toString().toLowerCase() ?? '';
            final formNo = client['form_no']?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery) || formNo.contains(_searchQuery);
          }).toList();
    }
    _filteredClients = tempClients;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await fetchRefundClients();
  }

  Future<void> processRefund({
    required String membershipNo,
    required String reason,
    required double totalPaid,
    required double refundAmount,
    required int installments,
    required int periodMonths,
  }) async {
    try {
      await _supabase.from('refunds').insert({
        'membership_no': membershipNo,
        'reason': reason,
        'total_paid': totalPaid,
        'refund_amount': refundAmount,
        'installments': installments,
        'period_months': periodMonths,
      });
      await updateRefundStatus(membershipNo, true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> revertRefund(String membershipNo) async {
    try {
      // Delete refund receipts
      final receiptsResponse = await _supabase
          .from('refund_receipts')
          .delete()
          .eq('membership_no', membershipNo);

      if (receiptsResponse.error != null) {
        throw Exception(
          'Failed to delete refund receipts: ${receiptsResponse.error!.message}',
        );
      }

      // Delete refund record
      final refundResponse = await _supabase
          .from('refunds')
          .delete()
          .eq('membership_no', membershipNo);

      if (refundResponse.error != null) {
        throw Exception(
          'Failed to delete refund record: ${refundResponse.error!.message}',
        );
      }

      // Update status
      await updateRefundStatus(membershipNo, false);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRefundStatus(String membershipNo, bool isRefunded) async {
    try {
      await _supabase
          .from('membership_forms')
          .update({'refunded': isRefunded})
          .eq('membership_no', membershipNo);
      final index = _allClients.indexWhere(
        (c) => c['membership_no'] == membershipNo,
      );
      if (index != -1) {
        _allClients[index]['refunded'] = isRefunded;
        _applyFiltersAndSearch();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaidReceipts(
    String membershipNo,
  ) async {
    try {
      final response = await _supabase
          .from('installment_receipts')
          .select()
          .eq('membership_no', membershipNo);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // endregion
}
