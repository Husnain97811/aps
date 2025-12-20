import 'dart:io';
import 'package:aps/config/models/addExpense_model.dart';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ReportPeriod { daily, weekly, monthly, custom }

enum CashflowCategory {
  income,
  expenses,
  monthlyIncome,
  monthlyExpenses,
  netCashflow,
}

class CashflowScreen extends StatefulWidget {
  const CashflowScreen({super.key});

  @override
  State<CashflowScreen> createState() => _CashflowScreenState();
}

class _CashflowScreenState extends State<CashflowScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  double totalReceived = 0.0;
  double totalDiscounts = 0.0;
  double totalOfferReceived = 0.0;
  double totalOfferDiscounts = 0.0;
  List<Expense> expenses = [];
  List<Expense> monthlyExpenses = [];
  double monthlyIncome = 0.0;
  double monthlyDiscounts = 0.0;
  double monthlyOfferReceived = 0.0;
  double monthlyOfferDiscounts = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;
  CashflowCategory? _selectedCategory;
  String? _selectedCategoryFilter;
  CashFlowProvider get _provider =>
      Provider.of<CashFlowProvider>(context, listen: false);

  // ADDED: Single visibility state for all values
  bool _showAllValues = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    // Use LoadingProvider instead of CashFlowProvider for overlay
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    await Future.wait([
      _fetchReceivedAmount(),
      _fetchMonthlyIncome(),
      _fetchExpenses(),
    ]).whenComplete(() {
      loadingProvider.stopLoading();
      _provider.setLoading(false);
    });
  }

  Future<void> _fetchReceivedAmount() async {
    try {
      final installmentResponse = await _supabase
          .from('installment_receipts')
          .select(
            'received_amount, offer_received_amount, discount, offer_discount_amount',
          );

      double installmentIncome = installmentResponse.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['received_amount'].toString()) ?? 0.0) +
            (double.tryParse(item['offer_received_amount'].toString()) ?? 0.0);
      });

      double installmentDiscounts = installmentResponse.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['discount'].toString()) ?? 0.0) +
            (double.tryParse(item['offer_discount_amount'].toString()) ?? 0.0);
      });

      double regularInstallmentIncome = installmentResponse.fold(0.0, (
        sum,
        item,
      ) {
        return sum +
            (double.tryParse(item['received_amount'].toString()) ?? 0.0);
      });

      double offerInstallmentIncome = installmentResponse.fold(0.0, (
        sum,
        item,
      ) {
        return sum +
            (double.tryParse(item['offer_received_amount'].toString()) ?? 0.0);
      });

      double regularDiscounts = installmentResponse.fold(0.0, (sum, item) {
        return sum + (double.tryParse(item['discount'].toString()) ?? 0.0);
      });

      double offerDiscounts = installmentResponse.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['offer_discount_amount'].toString()) ?? 0.0);
      });

      final cashInResponse = await _supabase.from('cash_in').select('amount');

      double cashInIncome = cashInResponse.fold(0.0, (sum, item) {
        return sum + (double.tryParse(item['amount'].toString()) ?? 0.0);
      });

      totalReceived = installmentIncome + cashInIncome;
      totalDiscounts = installmentDiscounts;
      totalOfferReceived = offerInstallmentIncome;
      totalOfferDiscounts = offerDiscounts;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching received amount: $e')),
      );
    }
  }

  Future<void> _fetchMonthlyIncome() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

      final installmentResponse = await _supabase
          .from('installment_receipts')
          .select(
            'received_amount, offer_received_amount, discount, offer_discount_amount, date',
          )
          .gte('date', startOfMonth.toIso8601String())
          .lt('date', startOfNextMonth.toIso8601String());

      double installmentMonthlyIncome = installmentResponse.fold(0.0, (
        sum,
        item,
      ) {
        return sum +
            (double.tryParse(item['received_amount'].toString()) ?? 0.0) +
            (double.tryParse(item['offer_received_amount'].toString()) ?? 0.0);
      });

      double monthlyInstallmentDiscounts = installmentResponse.fold(0.0, (
        sum,
        item,
      ) {
        return sum +
            (double.tryParse(item['discount'].toString()) ?? 0.0) +
            (double.tryParse(item['offer_discount_amount'].toString()) ?? 0.0);
      });

      double regularMonthlyIncome = installmentResponse.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['received_amount'].toString()) ?? 0.0);
      });

      double offerMonthlyIncome = installmentResponse.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['offer_received_amount'].toString()) ?? 0.0);
      });

      double regularMonthlyDiscounts = installmentResponse.fold(0.0, (
        sum,
        item,
      ) {
        return sum + (double.tryParse(item['discount'].toString()) ?? 0.0);
      });

      double offerMonthlyDiscounts = installmentResponse.fold(0.0, (sum, item) {
        return sum +
            (double.tryParse(item['offer_discount_amount'].toString()) ?? 0.0);
      });

      final cashInResponse = await _supabase
          .from('cash_in')
          .select('amount, date')
          .gte('date', startOfMonth.toIso8601String())
          .lt('date', startOfNextMonth.toIso8601String());

      double cashInMonthlyIncome = cashInResponse.fold(0.0, (sum, item) {
        return sum + (double.tryParse(item['amount'].toString()) ?? 0.0);
      });

      monthlyIncome = installmentMonthlyIncome + cashInMonthlyIncome;
      monthlyDiscounts = monthlyInstallmentDiscounts;
      monthlyOfferReceived = offerMonthlyIncome;
      monthlyOfferDiscounts = offerMonthlyDiscounts;
    } catch (e) {
      // Error handled by loading overlay timeout
    }
  }

  Future<void> _fetchExpenses() async {
    try {
      final response = await _supabase.from('expenses').select('*, dl_no');

      if (response.isNotEmpty) {
        setState(() {
          expenses = List<Expense>.from(
            response.map((expense) => Expense.fromJson(expense)),
          );
          monthlyExpenses =
              expenses
                  .where(
                    (expense) => expense.date.month == DateTime.now().month,
                  )
                  .toList();
        });
      }
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error Fetching expenses:  $e',
      );
    }
  }

  // ADDED: Toggle function for single eye button
  void _toggleAllValues() {
    setState(() {
      _showAllValues = !_showAllValues;
    });
  }

  // CHANGED: Wrapped with loading overlay and timeout
  void _handleRefresh() {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    _fetchInitialData().whenComplete(() {
      loadingProvider.stopLoading();
    });
  }

  Future<List<String>> _fetchExpenseCategories() async {
    try {
      final response = await _supabase
          .from('expenses')
          .select('category')
          .order('category', ascending: true);

      Set<String> categories = {};
      for (var item in response) {
        if (item['category'] != null) {
          categories.add(item['category'].toString());
        }
      }
      return ['All', ...categories];
    } catch (e) {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      if (_selectedCategory == CashflowCategory.expenses) {
        _showCategorySelectionDialog(ReportPeriod.custom);
      } else if (_selectedCategory != null) {
        _generatePDF(ReportPeriod.custom, _selectedCategory!);
      }
    }
  }

  Future<void> _showCategorySelectionDialog(ReportPeriod period) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Report Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('All'),
                  onTap: () {
                    Navigator.pop(context);
                    _generatePDF(
                      period,
                      _selectedCategory!,
                      categoryFilter: null,
                    );
                  },
                ),
                ListTile(
                  title: Text('Category Wise'),
                  onTap: () {
                    Navigator.pop(context);
                    _generatePDF(
                      period,
                      _selectedCategory!,
                      categoryFilter: 'category_wise',
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  // CHANGED: Wrapped PDF generation with loading overlay and timeout
  Future<void> _generatePDF(
    ReportPeriod period,
    CashflowCategory category, {
    String? categoryFilter,
  }) async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startPdfLoading();

    try {
      DateTime startDate;
      DateTime endDate = DateTime.now();

      switch (period) {
        case ReportPeriod.daily:
          startDate = DateTime.now().subtract(const Duration(days: 1));
          break;
        case ReportPeriod.weekly:
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case ReportPeriod.monthly:
          startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
          break;
        case ReportPeriod.custom:
          startDate = _startDate!;
          endDate = _endDate!;
          break;
      }

      late List<Map<String, dynamic>> data;
      String title = '';

      switch (category) {
        case CashflowCategory.income:
          final installmentData = await _fetchFilteredInstallmentData(
            startDate,
            endDate,
          );
          final cashInData = await _fetchFilteredData(
            'cash_in',
            startDate,
            endDate,
            amountField: 'amount',
          );
          data = [...installmentData, ...cashInData];
          title = 'Income Report';
          break;
        case CashflowCategory.expenses:
          data = await _fetchFilteredExpenseData(
            startDate,
            endDate,
            categoryFilter: categoryFilter,
          );
          title = 'Expenses Report';
          break;
        case CashflowCategory.monthlyIncome:
          final installmentMonthlyData = await _fetchMonthlyInstallmentData();
          final cashInMonthlyData = await _fetchMonthlyData(
            'cash_in',
            amountField: 'amount',
          );
          data = [...installmentMonthlyData, ...cashInMonthlyData];
          title = 'Monthly Income Report';
          break;
        case CashflowCategory.monthlyExpenses:
          data = await _fetchMonthlyExpenseData();
          title = 'Monthly Expenses Report';
          break;
        case CashflowCategory.netCashflow:
          final installmentIncomeData = await _fetchFilteredInstallmentData(
            startDate,
            endDate,
          );
          final cashInIncome = await _fetchFilteredData(
            'cash_in',
            startDate,
            endDate,
            amountField: 'amount',
          );
          final installmentDiscountData =
              await _fetchFilteredInstallmentDiscountData(startDate, endDate);
          final expensesData = await _fetchFilteredExpenseData(
            startDate,
            endDate,
          );
          data = [
            ...installmentIncomeData,
            ...cashInIncome,
            ...installmentDiscountData,
            ...expensesData,
          ];
          title = 'Net Cashflow Report';
          break;
      }

      final pdf = await PDFGenerator.generateCashflowPDF(
        title: 'Reliable Marketing Network Pvt Ltd',
        subtitle: title,
        data: data,
        period: period.toString().split('.').last,
        startDate: period == ReportPeriod.custom ? startDate : null,
        endDate: period == ReportPeriod.custom ? endDate : null,
        category: category,
        categoryFilter: categoryFilter,
      );

      final pdfData = await pdf.save();
      final tempDir = await getDownloadsDirectory();
      final tempFile = File('${tempDir!.path}/cashflow_report.pdf');
      await tempFile.writeAsBytes(pdfData);
      OpenFile.open(tempFile.path);
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Saved successfully to ${tempDir.path}',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      loadingProvider.stopPdfLoading();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredInstallmentData(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase
          .from('installment_receipts')
          .select('date, name, received_amount, offer_received_amount')
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date', ascending: true);

      return response.map<Map<String, dynamic>>((item) {
        final regularAmount =
            double.tryParse(item['received_amount'].toString()) ?? 0.0;
        final offerAmount =
            double.tryParse(item['offer_received_amount'].toString()) ?? 0.0;
        final totalAmount = regularAmount + offerAmount;

        return {
          'date': item['date'],
          'name': item['name'],
          'received_amount': regularAmount,
          'offer_received_amount': offerAmount,
          'amount': totalAmount,
        };
      }).toList();
    } catch (error, stackTrace) {
      print('Error fetching installment data: $error');
      print(stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredInstallmentDiscountData(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase
          .from('installment_receipts')
          .select('date, name, discount, offer_discount_amount')
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date', ascending: true);

      return response.map<Map<String, dynamic>>((item) {
        final regularDiscount =
            double.tryParse(item['discount'].toString()) ?? 0.0;
        final offerDiscount =
            double.tryParse(item['offer_discount_amount'].toString()) ?? 0.0;
        final totalDiscount = regularDiscount + offerDiscount;

        return {
          'date': item['date'],
          'description': 'Installment Discount',
          'category': 'Discounts',
          'amount': totalDiscount,
          'discount': regularDiscount,
          'offer_discount_amount': offerDiscount,
        };
      }).toList();
    } catch (error, stackTrace) {
      print('Error fetching installment discount data: $error');
      print(stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredExpenseData(
    DateTime start,
    DateTime end, {
    String? categoryFilter,
  }) async {
    try {
      var query = _supabase
          .from('expenses')
          .select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      if (categoryFilter != null &&
          categoryFilter != 'category_wise' &&
          categoryFilter != 'All') {
        query = query.eq('category', categoryFilter);
      }

      final response = await query.order('date', ascending: true);

      final installmentDiscounts = await _fetchFilteredInstallmentDiscountData(
        start,
        end,
      );

      List<Map<String, dynamic>> allExpenses = [];

      allExpenses.addAll(_processExpenseResponse(response));
      allExpenses.addAll(installmentDiscounts);

      return allExpenses;
    } catch (error, stackTrace) {
      print('Error fetching expense data: $error');
      print(stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMonthlyInstallmentData() async {
    final now = DateTime.now();
    return _fetchFilteredInstallmentData(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMonthlyExpenseData() async {
    final now = DateTime.now();
    return _fetchFilteredExpenseData(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFilteredData(
    String table,
    DateTime start,
    DateTime end, {
    String amountField = 'amount',
    String? categoryFilter,
  }) async {
    try {
      var query = _supabase
          .from(table)
          .select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      if (categoryFilter != null &&
          categoryFilter != 'category_wise' &&
          table == 'expenses') {
        query = query.eq('category', categoryFilter);
      }

      final response = await query.order('date', ascending: true);
      return _processResponse(response, amountField);
    } catch (error, stackTrace) {
      print('Error fetching filtered data from table "$table": $error');
      print(stackTrace);
      return [];
    }
  }

  List<Map<String, dynamic>> _processResponse(
    List<dynamic> response,
    String amountField,
  ) {
    return response.map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey(amountField)) {
          final dynamic value = item[amountField];
          if (value is String) {
            item[amountField] = double.tryParse(value) ?? 0.0;
          } else if (value is int) {
            item[amountField] = value.toDouble();
          }
        }
        return item;
      }
      return {};
    }).toList();
  }

  List<Map<String, dynamic>> _processExpenseResponse(List<dynamic> response) {
    return response.map<Map<String, dynamic>>((item) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey('amount')) {
          final dynamic value = item['amount'];
          if (value is String) {
            item['amount'] = double.tryParse(value) ?? 0.0;
          } else if (value is int) {
            item['amount'] = value.toDouble();
          }
        }

        if (item['category'] == 'Targeted Bonus' && item['dl_no'] != null) {
          return {
            ...item,
            'description': '${item['title']} (Dealer: ${item['dl_no']})',
          };
        }
        return item;
      }
      return {};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchMonthlyData(
    String table, {
    String amountField = 'amount',
  }) async {
    final now = DateTime.now();
    return _fetchFilteredData(
      table,
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
      amountField: amountField,
    );
  }

  void _showReportOptions(CashflowCategory category) {
    _selectedCategory = category;
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption('Daily Report', ReportPeriod.daily),
              _buildPeriodOption('Weekly Report', ReportPeriod.weekly),
              _buildPeriodOption('Monthly Report', ReportPeriod.monthly),
              _buildPeriodOption('Custom Range', ReportPeriod.custom),
            ],
          ),
    );
  }

  ListTile _buildPeriodOption(String title, ReportPeriod period) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (period == ReportPeriod.custom) {
          _showDateRangePicker();
        } else {
          if (_selectedCategory == CashflowCategory.expenses) {
            _showCategorySelectionDialog(period);
          } else {
            _generatePDF(period, _selectedCategory!);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalExpensesFromTable = expenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final totalExpenses = totalExpensesFromTable + totalDiscounts;
    final netCashflow = totalReceived - totalExpenses;

    // CHANGED: Wrap with LoadingOverlay
    return LoadingOverlay(
      child: Scaffold(
        body:
            _provider.isLoading
                ? ProviderLoadingWidget()
                : Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.rmncolor,
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAppBar(),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView(
                                children: [
                                  // CHANGED: Updated to use single visibility state
                                  _buildFinancialCard(
                                    'Total Income',
                                    totalReceived,
                                    CashflowCategory.income,
                                  ),
                                  _buildFinancialCard(
                                    'Total Expenses',
                                    totalExpenses,
                                    CashflowCategory.expenses,
                                  ),
                                  _buildFinancialCard(
                                    'Net Cashflow',
                                    netCashflow,
                                    CashflowCategory.netCashflow,
                                    isNet: true,
                                  ),
                                  // CHANGED: Updated to use single visibility state
                                  _buildBreakdownSection(),
                                  const SizedBox(height: 20),
                                  _buildExpenseChart(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  // CHANGED: Updated app bar with single eye button and refresh using LoadingProvider
  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Cashflow',
          style: GoogleFonts.aBeeZee(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.whitecolor,
          ),
        ),
        Row(
          children: [
            // ADDED: Single eye button to toggle all values
            IconButton(
              icon: Icon(
                _showAllValues ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: _toggleAllValues,
            ),
            IconButton(
              icon: const Icon(Icons.list_alt, color: Colors.white),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExpenseEntriesScreen(),
                    ),
                  ),
            ),
            // CHANGED: Refresh button now uses LoadingProvider with timeout
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _handleRefresh,
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                Navigator.pushNamed(context, RouteNames.addExpense);
              },
            ),
          ],
        ),
      ],
    );
  }

  // CHANGED: Simplified financial card without individual eye buttons
  Widget _buildFinancialCard(
    String title,
    double value,
    CashflowCategory category, {
    bool isNet = false,
  }) {
    return GestureDetector(
      onTap: () => _showReportOptions(category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(146, 10, 18, 33),
              const Color.fromARGB(173, 245, 127, 23),
              AppColors.lightgolden,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              // CHANGED: Use single visibility state
              _showAllValues ? '${value.toStringAsFixed(1)}' : '******',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color:
                    isNet
                        ? (value >= 0 ? Colors.green : Colors.red)
                        : (_showAllValues ? Colors.white : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CHANGED: Updated breakdown section to use single visibility state
  Widget _buildBreakdownSection() {
    final totalExpensesFromTable = expenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final regularIncome = totalReceived - totalOfferReceived;
    final regularExpenses = totalExpensesFromTable;
    final regularDiscounts = totalDiscounts - totalOfferDiscounts;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(146, 10, 18, 33),
            const Color.fromARGB(173, 245, 127, 23),
            AppColors.lightgolden,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income & Expense Breakdown',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Income Breakdown',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          _buildBreakdownItem('Regular Income', regularIncome),
          _buildBreakdownItem('Offer Income', totalOfferReceived),
          const SizedBox(height: 12),
          Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          _buildBreakdownItem('Regular Expenses', regularExpenses),
          _buildBreakdownItem('Regular Discounts', regularDiscounts),
          _buildBreakdownItem('Offer Discounts', totalOfferDiscounts),
        ],
      ),
    );
  }

  // CHANGED: Updated to use single visibility state
  Widget _buildBreakdownItem(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            // CHANGED: Use single visibility state
            _showAllValues ? value.toStringAsFixed(1) : '******',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    final totalExpensesFromTable = expenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final totalExpenses = totalExpensesFromTable + totalDiscounts;
    final netCashflow = totalReceived - totalExpenses;

    final chartData = [
      ExpenseCategoryData('Total Income', totalReceived),
      ExpenseCategoryData('Total Expenses', totalExpenses),
      ExpenseCategoryData('Net Cashflow', netCashflow),
    ];

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(146, 10, 18, 33),
            const Color.fromARGB(173, 245, 127, 23),
            AppColors.lightgolden,
          ],
          stops: [0.0, 0.3, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(3.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cashflow Breakdown',
                style: GoogleFonts.aBeeZee(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              // ADDED: Chart values toggle
            ],
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 25.h,
            child: SfCircularChart(
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.scroll,
                textStyle: TextStyle(color: Colors.white, fontSize: 9.sp),
              ),
              series: <CircularSeries>[
                PieSeries<ExpenseCategoryData, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) => data.category,
                  yValueMapper: (data, _) => data.amount,
                  dataLabelSettings: DataLabelSettings(
                    // CHANGED: Show values in chart based on visibility state
                    isVisible: _showAllValues,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  explode: true,
                  explodeIndex: 1,
                  pointColorMapper: (data, _) {
                    if (data.category == 'Total Income') {
                      return Colors.green;
                    } else if (data.category == 'Total Expenses') {
                      return Colors.red;
                    } else if (data.category == 'Net Cashflow') {
                      return Colors.white;
                    }
                    return Colors.black;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseCategoryData {
  final String category;
  final double amount;

  ExpenseCategoryData(this.category, this.amount);
}
