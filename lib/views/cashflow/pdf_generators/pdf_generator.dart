import 'package:aps/views/cashflow/cashflow_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

class PDFGenerator {
  static Future<pw.Font> _loadCustomFont() async {
    final fontData = await rootBundle.load("assets/fonts/roboto_regular.ttf");
    return pw.Font.ttf(fontData.buffer.asByteData());
  }

  static Future<pw.Document> generateCashflowPDF({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> data,
    required String period,
    DateTime? startDate,
    DateTime? endDate,
    required CashflowCategory category,
    String? categoryFilter,
  }) async {
    final pdf = pw.Document();
    final customFont = await _loadCustomFont();
    final primaryColor = PdfColors.blueGrey800;

    // Text Styles
    final titleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 18.8,
      color: PdfColors.black,
    );
    final subtitleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 13.8,
      color: PdfColors.black,
    );
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 12,
      color: PdfColors.black,
    );
    final bodyStyle = pw.TextStyle(fontSize: 9.5, color: PdfColors.black);
    final subHeadingStyle = pw.TextStyle(
      fontSize: 7,
      color: PdfColors.black,
      fontWeight: pw.FontWeight.bold,
    );

    // Net Cashflow Calculations - CHANGED HERE: Now includes both regular and offer amounts
    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    if (category == CashflowCategory.netCashflow) {
      for (var item in data) {
        // Income from both regular received_amount and offer_received_amount
        if (item.containsKey('received_amount') ||
            item.containsKey('offer_received_amount')) {
          totalIncome +=
              _parseAmount(item['received_amount'] ?? 0) +
              _parseAmount(item['offer_received_amount'] ?? 0);
        }

        // Expenses from both discount and offer_discount_amount
        if (item.containsKey('discount') ||
            item.containsKey('offer_discount_amount')) {
          totalExpenses +=
              _parseAmount(item['discount'] ?? 0) +
              _parseAmount(item['offer_discount_amount'] ?? 0);
        }

        // Expenses from expense records
        if (item.containsKey('amount') &&
            !item.containsKey('received_amount') &&
            !item.containsKey('offer_received_amount')) {
          totalExpenses += _parseAmount(item['amount']);
        }
      }
    }

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final formattedStartDate =
        startDate != null ? dateFormatter.format(startDate) : 'N/A';
    final formattedEndDate =
        endDate != null ? dateFormatter.format(endDate) : 'N/A';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              children: [
                pw.Text(title, style: titleStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  'A P S',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 15,
                    color: PdfColors.black,
                  ),
                ),

                pw.Text(subtitle, style: subtitleStyle),
                pw.Divider(color: primaryColor),
                pw.SizedBox(height: 34),
              ],
            );
          }
          return pw.SizedBox.shrink();
        },
        footer:
            (context) => pw.Center(
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ),
        build: (context) {
          return [
            if (period == 'custom') ...[
              pw.Text(
                'Start Date: $formattedStartDate',
                style: subHeadingStyle,
              ),
              pw.Text('End Date: $formattedEndDate', style: subHeadingStyle),
              pw.SizedBox(height: 10),
            ],

            // Net Cashflow Visualization - CHANGED: Now shows proper totals
            if (category == CashflowCategory.netCashflow) ...[
              _buildNetSummary(totalIncome, totalExpenses),
              pw.SizedBox(height: 20),
              _buildComparisonChart(totalIncome, totalExpenses),
              pw.SizedBox(height: 20),
              _buildPercentageBreakdown(totalIncome, totalExpenses),
              pw.SizedBox(height: 20),
              _buildNetResult(totalIncome, totalExpenses),
              pw.SizedBox(height: 40),
            ] else if (category == CashflowCategory.expenses &&
                categoryFilter == 'category_wise')
              _buildCategoryWiseExpenses(data, headerStyle, bodyStyle)
            else if (category != CashflowCategory.netCashflow) ...[
              // Existing table for income/expenses
              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 4,
                ),
                border: pw.TableBorder.all(color: PdfColors.black),
                headers: _buildTableHeader(category),
                data: _buildTableData(data, category),
                cellStyle: bodyStyle,
                headerStyle: headerStyle,
                columnWidths: {
                  for (int i = 0; i < _buildTableHeader(category).length; i++)
                    i: const pw.FixedColumnWidth(90),
                },
              ),
              pw.SizedBox(height: 20),
              _buildTotalRow(
                'Total Amount',
                _calculateTotal(data, category),
                headerStyle,
              ),
            ],

            // Common footer
            pw.SizedBox(height: 100),
            _buildSignatureSection(),
          ];
        },
      ),
    );

    return pdf;
  }

  // ================== NET CASHFLOW WIDGETS ================== //
  static pw.Widget _buildNetSummary(double income, double expenses) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildSummaryCard('Total Income', income, PdfColors.green),
        _buildSummaryCard('Total Expenses', expenses, PdfColors.red),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, color: color)),
          pw.SizedBox(height: 5),
          pw.Text(
            _formatAmount(absolute: true, amount: amount),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildComparisonChart(double income, double expenses) {
    final maxValue = income > expenses ? income : expenses;
    return pw.Container(
      height: 200,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.SizedBox(height: 20),
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildBar('Income', income, maxValue, PdfColors.green),
                _buildBar('Expenses', expenses, maxValue, PdfColors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBar(
    String label,
    double value,
    double maxValue,
    PdfColor color,
  ) {
    final barHeight = (value / maxValue) * 120;
    return pw.Expanded(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            height: barHeight,
            margin: const pw.EdgeInsets.symmetric(horizontal: 20),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: const pw.BorderRadius.vertical(
                top: pw.Radius.circular(4),
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _formatAmount(absolute: true, amount: value),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPercentageBreakdown(double income, double expenses) {
    final total = income + expenses;
    final incomePercent = total != 0 ? (income / total) * 100 : 0;
    final expensePercent = total != 0 ? (expenses / total) * 100 : 0;

    return pw.Column(
      children: [
        pw.Text(
          'Income And Expenses Ratio',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 30,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: (incomePercent / 100) * 200,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    bottomLeft: pw.Radius.circular(4),
                  ),
                ),
              ),
              pw.Container(
                width: (expensePercent / 100) * 200,
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  borderRadius: const pw.BorderRadius.only(
                    topRight: pw.Radius.circular(4),
                    bottomRight: pw.Radius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Income: ${incomePercent.toStringAsFixed(1)}%',
              style: pw.TextStyle(color: PdfColors.green, fontSize: 12),
            ),
            pw.Text(
              'Expenses: ${expensePercent.toStringAsFixed(1)}%',
              style: pw.TextStyle(color: PdfColors.red, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildNetResult(double income, double expenses) {
    final net = income - expenses;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Net Cashflow: ',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            _formatAmount(amount: net),
            style: pw.TextStyle(
              fontSize: 16,
              color: net >= 0 ? PdfColors.green : PdfColors.red,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================== EXISTING HELPERS ================== //

  static pw.Widget _buildTotalRow(
    String label,
    double amount,
    pw.TextStyle style,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              child: pw.Text(label, style: style),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                child: pw.Text(
                  _formatAmount(absolute: true, amount: amount),
                  style: style,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Align(
      alignment: pw.Alignment.bottomRight,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            alignment: pw.Alignment.bottomRight,
            width: 150,
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Authorized Signature',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryWiseExpenses(
    List<Map<String, dynamic>> data,
    pw.TextStyle headerStyle,
    pw.TextStyle bodyStyle,
  ) {
    final Map<String, double> categoryTotals = {};

    for (final item in data) {
      final category = item['category']?.toString() ?? 'Uncategorized';
      // CHANGED HERE: Include both discount and offer_discount_amount in expenses
      final amount =
          _parseAmount(item['amount'] ?? 0) +
          _parseAmount(item['discount'] ?? 0) +
          _parseAmount(item['offer_discount_amount'] ?? 0);
      categoryTotals.update(
        category,
        (value) => value + amount,
        ifAbsent: () => amount,
      );
    }

    final sortedCategories =
        categoryTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: {
            0: const pw.FixedColumnWidth(150),
            1: const pw.FixedColumnWidth(100),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Category', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Total Amount', style: headerStyle),
                ),
              ],
            ),
            ...sortedCategories.map(
              (entry) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(entry.key, style: bodyStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      _formatAmount(absolute: true, amount: entry.value),
                      style: bodyStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        _buildTotalRow(
          'Overall Total',
          categoryTotals.values.fold(0.0, (sum, amount) => sum + amount),
          headerStyle,
        ),
      ],
    );
  }

  static double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      if (amount.isEmpty) return 0.0;
      return double.tryParse(amount) ?? 0.0;
    }
    return 0.0;
  }

  static String _formatAmount({
    bool absolute = false,
    required dynamic amount,
  }) {
    final parsed = _parseAmount(amount);
    final value = absolute ? parsed.abs() : parsed;
    return '${value >= 0 ? '' : '-'} ${value.abs().toStringAsFixed(1)}';
  }

  // CHANGED HERE: Updated to include both regular and offer amounts/discounts
  static double _calculateTotal(
    List<Map<String, dynamic>> data,
    CashflowCategory category,
  ) {
    double total = 0.0;
    for (var item in data) {
      switch (category) {
        case CashflowCategory.income:
        case CashflowCategory.monthlyIncome:
          // Include both received_amount and offer_received_amount
          total +=
              _parseAmount(item['received_amount'] ?? 0) +
              _parseAmount(item['offer_received_amount'] ?? 0);
          break;
        case CashflowCategory.expenses:
        case CashflowCategory.monthlyExpenses:
          // Include amount from expenses table and discounts from installment receipts
          total +=
              _parseAmount(item['amount'] ?? 0) +
              _parseAmount(item['discount'] ?? 0) +
              _parseAmount(item['offer_discount_amount'] ?? 0);
          break;
        case CashflowCategory.netCashflow:
          // This is handled separately in generateCashflowPDF
          break;
      }
    }
    return total;
  }

  static List<String> _buildTableHeader(CashflowCategory category) {
    switch (category) {
      case CashflowCategory.income:
        return ['Date', 'Name', 'Amount'];
      case CashflowCategory.expenses:
        return ['Date', 'Description', 'Category', 'Amount'];
      case CashflowCategory.monthlyIncome:
        return ['Date', 'Amount', 'Description'];
      case CashflowCategory.monthlyExpenses:
        return ['Date', 'Description', 'Category', 'Amount'];
      case CashflowCategory.netCashflow:
        return [];
      default:
        return [];
    }
  }

  // CHANGED HERE: Updated to show combined amounts in table data
  static List<List<String>> _buildTableData(
    List<Map<String, dynamic>> data,
    CashflowCategory category,
  ) {
    List<List<String>> tableData = [];
    for (var item in data) {
      switch (category) {
        case CashflowCategory.income:
        case CashflowCategory.monthlyIncome:
          // Calculate combined income from both sources
          final combinedIncome =
              _parseAmount(item['received_amount'] ?? 0) +
              _parseAmount(item['offer_received_amount'] ?? 0);

          tableData.add([
            _formatDate(item['date']),
            (item['name']?.toString().isNotEmpty ?? false)
                ? item['name']
                    .toString()
                    .split(' ')
                    .map(
                      (word) =>
                          word.isNotEmpty
                              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                              : '',
                    )
                    .join(' ')
                : '',
            _formatAmount(absolute: true, amount: combinedIncome),
          ]);
          break;
        case CashflowCategory.expenses:
        case CashflowCategory.monthlyExpenses:
          // Calculate combined expenses from all sources
          final combinedExpense =
              _parseAmount(item['amount'] ?? 0) +
              _parseAmount(item['discount'] ?? 0) +
              _parseAmount(item['offer_discount_amount'] ?? 0);

          tableData.add([
            _formatDate(item['date']),
            item['description']?.toString() ?? '',
            item['category']?.toString() ?? '',
            _formatAmount(absolute: true, amount: combinedExpense),
          ]);
          break;
        case CashflowCategory.netCashflow:
          break;
      }
    }
    return tableData;
  }

  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is String) return date.split('T')[0];
    if (date is DateTime) return DateFormat('yyyy-MM-dd').format(date);
    return 'Invalid Date';
  }
}
