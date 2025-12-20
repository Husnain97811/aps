import 'dart:math';

import 'package:aps/services/admin_verification_service.dart';
import 'package:aps/views/clients/documents_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:aps/config/view.dart';

class Clients extends StatelessWidget {
  const Clients({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ClientsProvider()),
        ChangeNotifierProvider(create: (context) => LoadingProvider()),
      ],
      child: Stack(
        children: [
          const _ClientsView(),
          // Global PDF loading overlay
          Consumer<LoadingProvider>(
            builder: (context, loadingProvider, child) {
              return Visibility(
                visible: loadingProvider.isPdfLoading,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const ProviderLoadingWidget(),
                        SizedBox(height: 20),
                        Text(
                          'Generating PDF...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClientsView extends StatelessWidget {
  const _ClientsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Clients', style: GoogleFonts.aBeeZee(fontSize: 18.sp)),
      backgroundColor: AppColors.darkbrown,
      actions: [
        IconButton(
          tooltip: 'View/Update documents',
          icon: const Icon(
            Icons.document_scanner_sharp,
            color: AppColors.whitecolor,
          ),
          onPressed: () => _showDocumentDialog(context),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
          onPressed: () => context.read<ClientsProvider>().refreshData(),
        ),
      ],
    );
  }

  void _showDocumentDialog(BuildContext context) {
    final membershipController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Membership Number'),
            content: TextField(
              controller: membershipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Membership Number',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final membershipNo =
                      membershipController.text.toLowerCase().trim();
                  if (membershipNo.isNotEmpty) {
                    Navigator.pop(context);
                    _showDocumentOptions(context, membershipNo);
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _showDocumentOptions(BuildContext context, String membershipNo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Documents for $membershipNo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    try {
                      _showDocumentManager(context, membershipNo);
                    } catch (e) {
                      SupabaseExceptionHandler.showErrorSnackbar(
                        context,
                        'Error: $e',
                      );
                    }
                  },
                  child: const Text('View/Upload Documents'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _generatePdf(context, membershipNo);
                    } catch (e) {
                      SupabaseExceptionHandler.showErrorSnackbar(
                        context,
                        'Error: $e',
                      );
                    }
                  },
                  child: const Text('Generate Documents PDF'),
                ),
              ],
            ),
          ),
    );
  }

  void _showDocumentManager(BuildContext context, String membershipNo) {
    final loadingProvider = context.read<LoadingProvider>();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during loading
      builder: (context) {
        return LoadingOverlay(
          overlayColor: Colors.black.withOpacity(0.5),
          blur: 3.0,
          child: Dialog(
            child: DocumentManagerDialog(
              membershipNo: membershipNo,
              loadingProvider: loadingProvider,
            ),
          ),
        );
      },
    );
  }

  Future<void> _generatePdf(BuildContext context, String membershipNo) async {
    final loadingProvider = context.read<LoadingProvider>();
    final documentsProvider = DocumentsProvider();
    documentsProvider.setLoadingProvider(loadingProvider);

    try {
      loadingProvider.startLoading();
      await documentsProvider.generatePdf(membershipNo);
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'PDF generated successfully',
      );
    } catch (e) {
      loadingProvider.stopLoading();

      SupabaseExceptionHandler.showErrorSnackbar(context, 'Error $e');
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.rmncolorlight),
      child: Column(
        children: [
          _buildSearchBar(context),
          _buildFilterChips(context),
          SizedBox(height: 1.h),
          _buildClientList(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2.h),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Form No or Name...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.blackcolor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: AppColors.whitecolor,
        ),
        onChanged:
            (value) => context.read<ClientsProvider>().updateSearchQuery(value),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.h),
      child: Consumer<ClientsProvider>(
        builder: (context, provider, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip(context, 'All', 'all'),
              _buildFilterChip(context, 'Completed', 'winned'),
              _buildFilterChip(context, 'Blocked', 'suspended'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    return Consumer<ClientsProvider>(
      builder: (context, provider, _) {
        return FilterChip(
          label: Text(label),
          selected: provider.activeFilter == value,
          onSelected: (selected) => provider.updateFilter(value),
        );
      },
    );
  }

  Widget _buildClientList(BuildContext context) {
    return Expanded(
      child: Consumer<ClientsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.filteredClients.isEmpty) {
            return Center(child: ProviderLoadingWidget());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage!),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => provider.refreshData(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.filteredClients.isEmpty) {
            return const Center(child: Text('No Clients found'));
          }

          return _buildClientListView(context);
        },
      ),
    );
  }

  Widget _buildClientListView(BuildContext context) {
    return Consumer<ClientsProvider>(
      builder: (context, provider, _) {
        // Create a ScrollController
        final scrollController = ScrollController();

        return Scrollbar(
          controller: scrollController, // Assign the controller
          thumbVisibility: true, // Make the scrollbar always visible
          thickness: 8.0, // Set the thickness of the scrollbar
          radius: Radius.circular(4.0), // Round the corners of the scrollbar
          child: ListView.builder(
            controller: scrollController, // Assign the same controller
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            itemCount: provider.filteredClients.length,
            itemBuilder: (context, index) {
              final client = provider.filteredClients[index];
              return _ClientListItem(client: client);
            },
          ),
        );
      },
    );
  }

  Future<bool> isClientSuspended(String membershipNo) async {
    final response = await Supabase.instance.client
        .from('membership_forms')
        .select('suspended, winned')
        .eq('membership_no', membershipNo);

    final membershipData = response.first;
    return membershipData['suspended'] ?? false;
    return false;
  }

  Future<bool> isClientWinned(String membershipNo) async {
    final response = await Supabase.instance.client
        .from('membership_forms')
        .select('suspended, winned')
        .eq('membership_no', membershipNo);

    final membershipData = response.first;
    return membershipData['winned'] ?? false;
    return false;
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'addClient',
      mini: true,
      backgroundColor: AppColors.buttoncolor,
      onPressed: () => Navigator.pushNamed(context, RouteNames.membershipform),
      child: const Icon(Icons.add, color: AppColors.whitecolor),
    );
  }
}

class _ClientListItem extends StatelessWidget {
  final Map<String, dynamic> client;

  const _ClientListItem({required this.client});

  @override
  Widget build(BuildContext context) {
    // First check if client is refunded
    final isRefunded =
        client['refunded'] == true; // Assuming there's a 'refunded' field

    // Skip status checks if client is refunded
    final isOverdue =
        isRefunded
            ? false
            : context.watch<ClientsProvider>().isOverdue(
              client['membership_no'],
            );
    final isSuspended = isRefunded ? false : client['suspended'] == true;
    final isWinned = isRefunded ? false : client['winned'] == true;

    //   debugPrint('''
    // Building client ${client['name']}:
    // - Refunded: $isRefunded
    // - Suspended: $isSuspended
    // - Winned: $isWinned
    // - Overdue: $isOverdue
    // ''');

    return Card(
      elevation: 10,
      color:
          isSuspended
              ? Color.fromRGBO(223, 26, 26, 0.568) // Red for suspended
              : isWinned
              ? Color.fromRGBO(18, 175, 18, 1) // Green for winned
              : isOverdue
              ? const Color.fromARGB(123, 255, 255, 255) // Orange for overdue
              : Colors.white, // Default color
      margin: EdgeInsets.only(bottom: 1.5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        title: Text(
          client['name'].toString().toUpperCase() ?? 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
            color:
                isRefunded
                    ? Colors.black
                    : isSuspended
                    ? Colors.white
                    : isWinned
                    ? Colors.white
                    : AppColors.blackcolor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form No: ${client['form_no']}' ?? 'N/A',
              style: TextStyle(
                fontSize: 12.sp,
                color:
                    isRefunded
                        ? Colors.black
                        : isSuspended
                        ? Colors.white
                        : isWinned
                        ? Colors.white
                        : AppColors.blackcolor,
              ),
            ),
            if (isRefunded)
              Text(
                'REFUNDED',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing:
            isRefunded
                ? null // Hide action buttons for refunded clients
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Generate Statement',
                      icon: const Icon(Icons.picture_as_pdf),
                      color:
                          isSuspended
                              ? Colors.white
                              : isWinned
                              ? Colors.white
                              : Colors.blue,
                      onPressed: () => _generateClientPdf(context, client),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_sharp),
                      color: AppColors.darkbrown,
                      onSelected:
                          (value) => _handleMenuSelection(context, value),
                      itemBuilder: (BuildContext context) {
                        final isSuspended = client['suspended'] == true;
                        final isWinned = client['winned'] == true;

                        final menuItems = <String>[];
                        if (isSuspended) {
                          menuItems.add('Mark Normal (Suspended)');
                        } else if (isWinned) {
                          menuItems.add('Mark Normal (Fileclosed)');
                        } else {
                          menuItems.addAll([
                            'Mark Suspended',
                            'Mark File Closed',
                          ]);
                        }
                        menuItems.add('Edit Membership');

                        return menuItems.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(
                              choice,
                              style: TextStyle(
                                color: AppColors.whitecolor,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
        onTap: () => _showClientDetailsDialog(context, client),
      ),
    );
  }

  // function to edit membership form

  void _handleMenuSelection(BuildContext context, String value) async {
    if (value == 'Edit Membership') {
      final verfied = await AdminVerification.showVerificationDialog(
        context: context,
        action: 'Edit this MembershipForm',
      );
      if (!verfied) return;
      _navigateToEditForm(context);
    } else {
      final verfied = await AdminVerification.showVerificationDialog(
        context: context,
        action: 'Update Status',
      );
      if (!verfied) return;
      _handleStatusUpdate(context, value);
    }
  }

  // function to navigate to the edit form screen

  void _navigateToEditForm(BuildContext context) {
    final membershipNo = client['membership_no']?.toString();
    if (membershipNo == null || membershipNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership number is missing')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      RouteNames.membershipform,
      arguments: {'editMode': true, 'membershipNo': client['membership_no']},
    );
  }

  // // function to mark wined

  Future<void> _handleStatusUpdate(BuildContext context, String status) async {
    final membershipNo = client['membership_no']?.toString();
    final provider = context.read<ClientsProvider>();

    if (membershipNo == null || membershipNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership number is missing')),
      );
      return;
    }

    try {
      // Show remarks dialog for all status types
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatusRemarksDialog(status: status),
      );

      if (result == null) {
        // User canceled the dialog
        return;
      }

      final statusRemarks = result['statusRemarks']?.toString() ?? '';
      final confirmed = result['confirmed'] == true;

      if (!confirmed || statusRemarks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status remarks are required')),
        );
        return;
      }

      // Special handling for file closure
      if (status == 'Mark Fileclosed') {
        await provider.updateClientStatus(
          membershipNo,
          status,
          statusRemarks: statusRemarks,
          // plotNo: plotNo,
          // specialCategory: specialCategory,
          // additionalCharges: additionalCharges,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('File closed with remarks')));
      }
      // Handling for other status types
      else {
        final action = status.replaceAll('Mark ', '');
        await provider.updateClientStatus(
          membershipNo,
          status,
          statusRemarks: statusRemarks,
        );
        final errorMessage = SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Status Updated $action with remarks',
        );
        // SupabaseExceptionHandler.showSuccessSnackbar(context, errorMessage);
      }
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    }
  }

  void _showClientDetailsDialog(
    BuildContext context,
    Map<String, dynamic> client,
  ) {
    showDialog(
      context: context,
      builder: (context) => ClientDetailsDialog(client: client),
    );
  }

  // generates dynamic installments of client data

  Future<void> _generateClientPdf(
    BuildContext context,
    Map<String, dynamic> client,
  ) async {
    final loadingProvider = context.read<LoadingProvider>();

    try {
      // ================== LOGIC AND DATA FOR CLIENT STATEMENT PDF ==================
      loadingProvider.startPdfLoading();

      final membershipNo = client['membership_no']?.toString();
      if (membershipNo == null || membershipNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membership number is missing')),
        );
        return;
      }

      final supabase = Supabase.instance.client;
      final paymentPlan = client['payment_plan'] ?? 'Not Selected';

      // Fetch booking date, cost of land, and additional details from membership_forms table
      final membershipFormResponse =
          await supabase
              .from('membership_forms')
              .select(
                'date, cost_of_land, special_category, additional_charges',
              )
              .eq('membership_no', membershipNo)
              .single();

      // Parse the booking date
      final bookingDateStr =
          membershipFormResponse['date']?.toString() ?? 'N/A';
      final bookingDate =
          bookingDateStr != 'N/A'
              ? DateTime.parse(bookingDateStr)
              : DateTime.now(); // Fallback to current date if booking date is missing

      final costOfLand =
          double.tryParse(
            membershipFormResponse['cost_of_land']?.toString() ?? '0',
          ) ??
          0.0;

      // Fetch existing installments
      // Fetch existing installments with additional special offer fields
      final response = await supabase
          .from('installment_receipts')
          .select(
            'received_amount, discount, date, receipt_no, installment_no, special_offer, offer_received_amount, offer_discount_amount',
          )
          .eq('membership_no', membershipNo);

      List<Map<String, dynamic>> actualInstallments = [];
      if (response.isNotEmpty) {
        actualInstallments = List<Map<String, dynamic>>.from(response);
      }

      // Calculate total received amount
      // Calculate total received amount (include offer_received_amount for specials)
      double totalReceived = 0;
      double totalDiscount = 0;
      for (final installment in actualInstallments) {
        final receivedAmount =
            double.tryParse(
              installment['received_amount']?.toString() ?? '0',
            ) ??
            0.0;
        final offerReceivedAmount =
            double.tryParse(
              installment['offer_received_amount']?.toString() ?? '0',
            ) ??
            0.0;
        final discountAmount =
            double.tryParse(installment['discount']?.toString() ?? '0') ?? 0.0;
        final offerDiscountAmount =
            double.tryParse(
              installment['offer_discount_amount']?.toString() ?? '0',
            ) ??
            0.0;

        totalReceived += receivedAmount + offerReceivedAmount;
        totalDiscount += discountAmount + offerDiscountAmount;
      }

      // Calculate balance amount (subtract totalDiscount for consistency with table balances)

      // Calculate discount and additional charges for upper showing data not for installment logic
      final discount =
          double.tryParse(client['discount']?.toString() ?? '') ?? 0.0;
      final developmentCharges =
          double.tryParse(client['development_charges']?.toString() ?? '0') ??
          0.0;
      final additionalCharges =
          double.tryParse(
            membershipFormResponse['additional_charges']?.toString() ?? '0',
          ) ??
          0.0;
      double totalCost = costOfLand + additionalCharges;
      double balanceAmount =
          totalCost -
          totalReceived -
          totalDiscount; // Added - totalDiscount; comment out if you don't want this change

      // Calculate balance amount

      // Generate expected installments based on payment plan
      List<Map<String, dynamic>> expectedInstallments = [];
      double totalExpected = 0;

      if (paymentPlan == 'Simple Plan') {
        final totalInstallments = 36;
        final downpayment =
            double.tryParse(client['downpayment']?.toString() ?? '0') ?? 0.0;
        final monthlyInstallment =
            double.tryParse(client['monthly_installment']?.toString() ?? '0') ??
            0.0;

        // 1. Booking Installment
        expectedInstallments.add({
          'installment_no': 1,
          'description': 'Booking',
          'due_amount': downpayment,
          'due_date': bookingDate,
          'is_bold': true,
        });

        // 2. Determine first installment date
        DateTime currentDueDate;
        if (bookingDate.day <= 20) {
          // <-- Fix: Cutoff at 22 (not 20)
          // <-- changed on 3/20/2025 to 1-20
          // March 1–22 → April 10
          currentDueDate = DateTime(
            bookingDate.year,
            bookingDate.month + 1,
            10,
          );
        } else {
          // March 23–31 → May 10
          // override 21 to 31
          currentDueDate = DateTime(
            bookingDate.year,
            bookingDate.month + 2,
            10,
          );
        }

        // 3. Generate remaining installments
        for (int i = 2; i <= totalInstallments; i++) {
          expectedInstallments.add({
            'installment_no': i,
            'description': 'Installment',
            'due_amount': monthlyInstallment,
            'due_date': currentDueDate,
            'is_bold': false,
          });
          currentDueDate = DateTime(
            currentDueDate.year,
            currentDueDate.month + 1,
            10,
          );
        }
      } else if (paymentPlan == 'H.Y Installment Plan') {
        final monthlyInstallment =
            double.tryParse(client['monthly_installment']?.toString() ?? '0') ??
            0.0;
        final hyInstallment =
            double.tryParse(
              client['halfYear_Installment']?.toString() ?? '0',
            ) ??
            0.0;
        final downpayment =
            double.tryParse(client['downpayment']?.toString() ?? '0') ?? 0.0;

        // 1. Booking Installment
        expectedInstallments.add({
          'installment_no': 1,
          'description': 'Booking',
          'due_amount': downpayment,
          'due_date': bookingDate,
          'is_bold': true,
        });

        // 2. Determine first installment date (same logic)
        DateTime currentDueDate;
        if (bookingDate.day <= 20) {
          // <-- Fix: Cutoff at 22
          currentDueDate = DateTime(
            bookingDate.year,
            bookingDate.month + 1,
            10,
          );
        } else {
          currentDueDate = DateTime(
            bookingDate.year,
            bookingDate.month + 2,
            10,
          );
        }

        // 3. Generate Half-Yearly installments
        for (int i = 2; i <= 36; i++) {
          expectedInstallments.add({
            'installment_no': i,
            'description': i % 6 == 0 ? 'H.Y Installment' : 'Installment',
            'due_amount': i % 6 == 0 ? hyInstallment : monthlyInstallment,
            'due_date': currentDueDate,
            'is_bold': i % 6 == 0 ? true : false,
          });

          // Move to next month (monthly) or 6 months (half-yearly)
          currentDueDate =
              (i % 6 == 0)
                  ? DateTime(currentDueDate.year, currentDueDate.month + 1, 10)
                  : DateTime(currentDueDate.year, currentDueDate.month + 1, 10);
        }
      } else if (paymentPlan == 'Cash') {
        // For Cash plan, only one installment
        expectedInstallments.add({
          'installment_no': 1,
          'description': 'Booking (10% Discount + Development Charges)',
          'due_amount': totalCost,
        });
        totalExpected = totalCost;
      }

      // Determine displayed cost and balance based on payment plan
      final displayedCost = costOfLand; // Show original cost of land
      final displayedBalance =
          balanceAmount; // Show balance after discounts and charges

      // Create actual installments map
      final actualInstallmentMap = <int, Map<String, dynamic>>{};
      for (final installment in actualInstallments) {
        final installmentNo =
            int.tryParse(installment['installment_no']?.toString() ?? '') ?? 0;
        if (installmentNo > 0) {
          actualInstallmentMap[installmentNo] = installment;
        }
      }

      // Define base font size and reduce it by 20%
      const baseFontSize = 9.0;
      final reducedFontSize = baseFontSize * 0.8;

      // Initialize totalDue and totalBalance
      double totalDue = 0;
      double totalBalance = 0;

      // Generate table data
      final tableData = generateTableData(
        bookingDate,
        expectedInstallments,
        actualInstallmentMap,
        reducedFontSize,
        (double due, double balance) {
          totalDue = due;
          totalBalance = balance;
        },
      );

      // PDF Generation
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

      //
      // ================== PAGE DATA AND ALIGNMENT FOR CLIENT STATEMENT PDF ==================

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
                            'Account Statement',
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
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // member info headings column
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
                          //member info  values column
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                client['membership_no']
                                    .toString()
                                    .toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: reducedFontSize,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                '${client['cnic_passport_no'] ?? 'N/A'}',
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
                                '${client['mobile_no'] ?? 'N/A'}',
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
                          padding: pw.EdgeInsets.only(right: 10),
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

                // Plot Information
                pw.SizedBox(height: 8),
                pw.Header(
                  text: 'Plot Information',
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
                    // Left Column: Plot Size, Category, Time Duration
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Plot Size:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'Plot Type:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                // if (client['special_category'] != null)
                                //   pw.SizedBox(height: 5),
                                // if (client['special_category'] != null)
                                pw.SizedBox(height: 5),

                                pw.Text(
                                  'Category:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'Plot No:',
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
                                  '${client['plot_size']} M' ??
                                      'N/A', // plot size
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  client['category'].toString() ?? 'N/A',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                // if (client['special_category'] != null)
                                //   pw.SizedBox(height: 5),
                                // if (client['special_category'] != null)
                                pw.SizedBox(height: 5),

                                pw.Text(
                                  client['special_category'] == null ||
                                          client['special_category']
                                              .toString()
                                              .isEmpty
                                      ? 'General'
                                      : client['special_category']
                                              .toString()[0]
                                              .toUpperCase() +
                                          client['special_category']
                                              .toString()
                                              .substring(1),

                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),

                                pw.Text(
                                  '${client['plot_no'] ?? 'Not Granted'}',
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
                    ),
                    pw.SizedBox(width: 15),
                    // Right Column: Booking Date, Plot No., Discount
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        // alignment: pw.Alignment.topLeft,
                        width: 200,
                        child: pw.Row(
                          // crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            pw.Column(
                              // mainAxisAlignment: pw.MainAxisAlignment.start,
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Booking Date:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                // plot no
                                pw.Text(
                                  'Time Duration:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'File Status:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  '-',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
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
                                  DateFormat('dd/MM/yyyy').format(bookingDate),
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  paymentPlan == 'Cash' ? 'Cash' : '3 Years',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),

                                pw.SizedBox(height: 5),
                                // File Status Logic
                                if (client['suspended'] == true)
                                  pw.Text(
                                    'BLOCKED',
                                    style: pw.TextStyle(
                                      fontSize: reducedFontSize,
                                      color: PdfColors.red,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  )
                                else if (client['winned'] == true)
                                  pw.Text(
                                    'COMPLETED',
                                    style: pw.TextStyle(
                                      fontSize: reducedFontSize,
                                      color: PdfColors.green,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  )
                                else
                                  pw.Text(
                                    'NORMAL',
                                    style: pw.TextStyle(
                                      fontSize: reducedFontSize,
                                      color: PdfColors.blue,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  '-',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Payment Information
                pw.SizedBox(height: 8),
                pw.Header(
                  text: 'Payment Details',
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
                    // Left Column: Cost of Land and Received Amount
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Cost of Land:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'Received Amount:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'Balance Amount:',
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
                                  displayedCost.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  totalReceived.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  displayedBalance.toStringAsFixed(0),
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
                    ),
                    pw.SizedBox(width: 15),
                    // Right Column: Discount and Additional Charges
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        alignment: pw.Alignment.topLeft,
                        width: 200,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Development Charges:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'Category Charges:',
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  'Discount:',
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
                                  developmentCharges.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  additionalCharges.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 5),
                                pw.Text(
                                  discount.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                    fontSize: reducedFontSize,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Installments Table
                pw.SizedBox(height: 28),
                pw.Table(
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1), // Booking Date
                    1: pw.FlexColumnWidth(1.9), // Plot No.
                    2: pw.FlexColumnWidth(1.4),
                    3: pw.FlexColumnWidth(1.5), // Due Date
                    4: pw.FlexColumnWidth(1.5), // Amount Received

                    5: pw.FlexColumnWidth(1.2), // Booking Date
                    6: pw.FlexColumnWidth(1.1), // Discount column (NEW)
                    7: pw.FlexColumnWidth(1.2), // Plot No.
                    8: pw.FlexColumnWidth(1.4), // Installment No.
                    9: pw.FlexColumnWidth(1.3), // Due Date
                  },
                  children: [
                    _buildTableHeader(reducedFontSize),
                    ...tableData,
                    _buildTotalRow(
                      9,
                      totalDue,
                      totalReceived,
                      totalBalance,
                      totalDiscount,
                    ),
                  ],
                ),
              ],
        ),
      );

      // Save and open PDF
      final output = await getDownloadsDirectory();
      final file = File('${output!.path}/client_${membershipNo}_statement.pdf');
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(file.path);

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'PDF generated successfully!',
      );
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      loadingProvider.stopPdfLoading();
    }
  }

  List<pw.TableRow> generateTableData(
    DateTime bookingDate,
    List<Map<String, dynamic>> expectedInstallments,
    Map<int, dynamic> actualInstallmentMap, // This will be for normals only
    double reducedFontSize,
    void Function(double totalDue, double totalBalance) updateTotalCallback,
  ) {
    List<pw.TableRow> tableData = [];
    final actualInstallments = actualInstallmentMap.values.toList();

    // Separate normal and special receipts
    final normalInstallments =
        actualInstallments
            .where((i) => !(i['special_offer'] ?? false))
            .toList();
    final specialInstallments =
        actualInstallments.where((i) => i['special_offer'] ?? false).toList();

    // Create normal map (as before, but only normals)
    final actualInstallmentMapNormal = <int, Map<String, dynamic>>{};
    for (final installment in normalInstallments) {
      final installmentNo =
          int.tryParse(installment['installment_no']?.toString() ?? '') ?? 0;
      if (installmentNo > 0) {
        actualInstallmentMapNormal[installmentNo] = installment;
      }
    }

    // Precompute lists for applied values (index 0 = installment 1)
    final int numInstallments = expectedInstallments.length;
    final List<double> dues =
        expectedInstallments.map((e) => e['due_amount'] as double).toList();
    List<double> displayReceivedAmounts = List.filled(numInstallments, 0.0);
    List<double> appliedDiscountAmounts = List.filled(numInstallments, 0.0);
    List<double> balances =
        dues.map((d) => d).toList(); // Start with dues as balances

    // Maps for last three columns (populate for both normal and special)
    final Map<int, String> receiptNos = {};
    final Map<int, String> paidDates = {};
    final Map<int, double> rawPaidAmounts = {};

    // First pass: Apply normal receipts forward (with excess carry, as before)
    double excessAmount = 0.0;
    double excessDiscount = 0.0;
    for (int i = 0; i < numInstallments; i++) {
      final expected = expectedInstallments[i];
      final installmentNo = expected['installment_no'] as int;
      final dueAmount = dues[i];

      final actual = actualInstallmentMapNormal[installmentNo];
      double paidAmount =
          actual != null
              ? (double.tryParse(
                    actual['received_amount']?.toString() ?? '0',
                  ) ??
                  0.0)
              : 0.0;
      double discountAmount =
          actual != null
              ? (double.tryParse(actual['discount']?.toString() ?? '0') ?? 0.0)
              : 0.0;

      // Populate last three columns for normal
      if (actual != null) {
        receiptNos[installmentNo] = actual['receipt_no']?.toString() ?? '';
        paidDates[installmentNo] = formatPaidDate(actual);
        rawPaidAmounts[installmentNo] =
            paidAmount; // Uses received_amount for normals
      }

      double totalReceivedForInstallment = paidAmount + excessAmount;
      double totalDiscountForInstallment = discountAmount + excessDiscount;

      double appliedReceivedAmount = min(
        totalReceivedForInstallment,
        balances[i],
      ); // Apply to current balance
      excessAmount = totalReceivedForInstallment - appliedReceivedAmount;

      double remainingDue = balances[i] - appliedReceivedAmount;

      double appliedDiscountAmount = min(
        totalDiscountForInstallment,
        remainingDue,
      );
      excessDiscount = totalDiscountForInstallment - appliedDiscountAmount;

      displayReceivedAmounts[i] = appliedReceivedAmount;
      appliedDiscountAmounts[i] = appliedDiscountAmount;
      balances[i] = remainingDue - appliedDiscountAmount;
    }

    // Second pass: Apply special receipts backward (start from end, carry excess backward)
    // Sort specials by date ascending (earlier specials applied first); adjust if needed
    specialInstallments.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(0);
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(0);
      return dateA.compareTo(dateB);
    });

    for (final special in specialInstallments) {
      double offerRec =
          double.tryParse(
            special['offer_received_amount']?.toString() ?? '0',
          ) ??
          0.0;
      double offerDisc =
          double.tryParse(
            special['offer_discount_amount']?.toString() ?? '0',
          ) ??
          0.0;

      // Populate last three columns for special (using original installment_no, unchanged)
      final installmentNo =
          int.tryParse(special['installment_no']?.toString() ?? '0') ?? 0;
      if (installmentNo > 0 && installmentNo <= numInstallments) {
        receiptNos[installmentNo] = special['receipt_no']?.toString() ?? '';
        paidDates[installmentNo] = formatPaidDate(special);
        rawPaidAmounts[installmentNo] =
            double.tryParse(
              special['offer_received_amount']?.toString() ?? '0',
            ) ??
            0.0; // Show offer_received_amount for specials
      }

      // Apply offer_received_amount backward (as received)
      for (int j = numInstallments - 1; j >= 0; j--) {
        if (offerRec <= 0) break;
        double applyRec = min(offerRec, balances[j]);
        displayReceivedAmounts[j] += applyRec;
        balances[j] -= applyRec;
        offerRec -= applyRec;
      }

      // Apply offer_discount backward (as discount)
      for (int j = numInstallments - 1; j >= 0; j--) {
        if (offerDisc <= 0) break;
        double applyDisc = min(offerDisc, balances[j]);
        appliedDiscountAmounts[j] += applyDisc;
        balances[j] -= applyDisc;
        offerDisc -= applyDisc;
      }
    }

    // Now build table rows using precomputed values
    double totalDue = 0.0;
    double totalBalance = 0.0;
    for (int i = 0; i < numInstallments; i++) {
      final expected = expectedInstallments[i];
      final installmentNo = expected['installment_no'] as int;
      final description = expected['description'] as String;
      final dueDate = expected['due_date'] as DateTime;
      final formattedDate = DateFormat('dd/MM/yyyy').format(dueDate);
      final isBold = expected['is_bold'] ?? false;
      final isHYInstallment = description.contains('H.Y Installment');
      final isdownPayment = description.contains('Booking');

      final receiptNo = receiptNos[installmentNo] ?? '';
      final paidDate = paidDates[installmentNo] ?? '';
      final paidAmount = rawPaidAmounts[installmentNo] ?? 0.0;

      totalDue += dues[i];
      totalBalance += balances[i];

      tableData.add(
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            _buildTableCell(
              installmentNo.toString(),
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              description,
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              installmentNo == 1
                  ? DateFormat('dd/MM/yyyy').format(bookingDate)
                  : formattedDate,
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              dues[i].toStringAsFixed(0),
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              displayReceivedAmounts[i].toStringAsFixed(0),
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              balances[i].toStringAsFixed(0),
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              appliedDiscountAmounts[i].toStringAsFixed(0),
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(width: 1)),
              ),
              child: _buildTableCell(
                receiptNo,
                reducedFontSize,
                isBold || isHYInstallment || isdownPayment,
              ),
            ),
            _buildTableCell(
              paidDate,
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
            _buildTableCell(
              paidAmount.toStringAsFixed(0),
              reducedFontSize,
              isBold || isHYInstallment || isdownPayment,
            ),
          ],
        ),
      );
    }

    updateTotalCallback(totalDue, totalBalance);
    return tableData;
  }

  String formatPaidDate(Map<String, dynamic> installment) {
    try {
      final dateStr = installment['date']?.toString();
      if (dateStr == null || dateStr.isEmpty) return '';
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  pw.Widget _buildTableCell(String text, double fontSize, bool isBold) {
    if (text.trim().isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Container(),
      );
    }

    return pw.Padding(
      child: pw.Text(
        textAlign: pw.TextAlign.center,
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
      padding: const pw.EdgeInsets.all(2),
    );
  }

  pw.TableRow _buildTableHeader(double reducedFontSize) {
    return pw.TableRow(
      children: [
        _buildTableHeaderCell('Inst No.', reducedFontSize),
        _buildTableHeaderCell('Payment Description', reducedFontSize),
        _buildTableHeaderCell('Date', reducedFontSize),
        _buildTableHeaderCell('Due Amount', reducedFontSize),
        _buildTableHeaderCell('Received Amount', reducedFontSize),
        _buildTableHeaderCell('Balance', reducedFontSize),
        _buildTableHeaderCell('Discount', reducedFontSize),

        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(width: 1)),
          ),
          child: _buildTableHeaderCell('Receipt\nNo.', reducedFontSize),
        ),
        _buildTableHeaderCell('Paid Date', reducedFontSize),
        _buildTableHeaderCell('Paid Amount', reducedFontSize),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(String text, double reducedFontSize) {
    return pw.Padding(
      child: pw.Text(
        textAlign: pw.TextAlign.center,
        text,
        style: pw.TextStyle(
          fontSize: reducedFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      padding: const pw.EdgeInsets.all(2),
    );
  }

  pw.TableRow _buildTotalRow(
    double reducedFontSize,
    double totalDue,
    double totalReceived,
    double totalBalance,
    double
    totalDiscount, // Add this parameter if you want to show total discount
  ) {
    return pw.TableRow(
      children: [
        _buildTotalCell('Total', 9),
        _buildTotalCell('', reducedFontSize),
        _buildTotalCell('', reducedFontSize),
        _buildTotalCell(totalDue == 0 ? '' : totalDue.toStringAsFixed(0), 9),
        _buildTotalCell(
          totalReceived == 0 ? '' : totalReceived.toStringAsFixed(0),
          9,
        ),
        _buildTotalCell(
          totalBalance == 0 ? '' : totalBalance.toStringAsFixed(0),
          9,
        ),
        _buildTotalCell(
          totalDiscount == 0
              ? ''
              : totalDiscount.toStringAsFixed(0), // Total discount
          9,
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(width: 1)),
          ),
          child: _buildTotalCell('', reducedFontSize),
        ),
        _buildTotalCell('', reducedFontSize),
        _buildTotalCell(
          totalReceived == 0 ? '' : totalReceived.toStringAsFixed(0),
          9,
        ),
      ],
    );
  }

  pw.Widget _buildTotalCell(String text, double reducedFontSize) {
    if (text.trim().isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Container(),
      );
    }

    return pw.Padding(
      child: pw.Text(
        textAlign: pw.TextAlign.center,
        text,
        style: pw.TextStyle(
          fontSize: reducedFontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      padding: const pw.EdgeInsets.all(2),
    );
  }
}

class ClientDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> client;

  const ClientDetailsDialog({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        client['membership_no']?.toString().toUpperCase() ?? 'N/A',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textcolor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', client['name']),
            _buildDetailRow('CNIC/Passport', client['cnic_passport_no']),
            _buildDetailRow('Mobile', client['mobile_no']),
            _buildDetailRow('Address', client['address']),
            _buildDetailRow(
              'Membership No',
              client['membership_no'].toString().toUpperCase(),
            ),
            _buildDetailRow('Date', client['date']),
            SizedBox(height: 2.h),
            Text(
              'Next of Kin Info:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppColors.textcolor,
              ),
            ),
            _buildDetailRow('Name', client['nok_name']),
            _buildDetailRow('Relation', client['relation']),
            _buildDetailRow('Mobile', client['nok_mobile_no']),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: AppColors.buttoncolor)),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      backgroundColor: AppColors.whitecolor,
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    // Capitalize each word except for the membership number
    String formattedValue =
        (label == 'Membership No')
            ? value?.toString() ??
                'N/A' // Leave membership number as is
            : capitalizeEachWord(
              value?.toString() ?? 'N/A',
            ); // Capitalize other fields

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(formattedValue)),
        ],
      ),
    );
  }

  // Helper function to capitalize the first letter of each word
  String capitalizeEachWord(String input) {
    if (input.isEmpty) return input;

    List<String> words = input.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] =
            words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
      }
    }
    return words.join(' ');
  }
}

class StatusRemarksDialog extends StatefulWidget {
  final String status;

  const StatusRemarksDialog({super.key, required this.status});

  @override
  State<StatusRemarksDialog> createState() => _StatusRemarksDialogState();
}

class _StatusRemarksDialogState extends State<StatusRemarksDialog> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.status} - Add Remarks'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Status Remarks',
                hintText: 'Enter reason for status change',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Remarks are required';
                }
                return null;
              },
            ),
            if (_isSubmitting) const SizedBox(height: 16),
            if (_isSubmitting) const CircularProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isSubmitting
                  ? null
                  : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isSubmitting = true);
                      // Simulate processing delay
                      await Future.delayed(const Duration(milliseconds: 100));
                      Navigator.pop(context, {
                        'confirmed': true,
                        'statusRemarks': _remarksController.text,
                      });
                    }
                  },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
