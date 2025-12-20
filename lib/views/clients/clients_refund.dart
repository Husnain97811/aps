import 'package:aps/config/providers/clients_refund_provider.dart';
import 'package:aps/config/view.dart';
import 'package:aps/views/clients/refund_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsRefund extends StatelessWidget {
  const ClientsRefund({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClientsRefundProvider>(
      create: (context) => ClientsRefundProvider(),
      child: const _ClientsRefundView(),
    );
  }
}

class _ClientsRefundView extends StatelessWidget {
  const _ClientsRefundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  AppBar _buildAppBar(BuildContext context) {
    final provider = context.watch<ClientsRefundProvider>();
    return AppBar(
      title: Text(
        'Clients Refund',
        style: GoogleFonts.aBeeZee(fontSize: 18.sp),
      ),
      backgroundColor: AppColors.darkbrown,
      actions: [
        // Button for Refund Slip (opens dialog)
        IconButton(
          icon: const Icon(Icons.list_alt, color: AppColors.whitecolor),
          tooltip: 'Fetch All Receipts',
          onPressed: () {
            Navigator.pushNamed(context, RouteNames.refundreceipts);
          },
        ),
        IconButton(
          icon: const Icon(Icons.receipt_long, color: AppColors.whitecolor),
          tooltip: 'Generate Receipt',
          onPressed: () {
            _showRefundSlipDialog(context);
          },
        ),

        // Refresh Button
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
          onPressed: () => provider.refreshData(),
        ),
      ],
    );
  }

  void _showRefundSlipDialog(BuildContext context) {
    // We need access to the provider in the dialog, but the dialog
    // has its own context. To pass the provider, we wrap it.
    showDialog(
      context: context,
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<ClientsRefundProvider>(),
            child: const _RefundSlipDialog(),
          ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.rmncolorlight),
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
            (value) =>
                context.read<ClientsRefundProvider>().updateSearchQuery(value),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip(context, 'Blocked', 'suspended'),
          _buildFilterChip(context, 'Refunded', 'refunded'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    return Consumer<ClientsRefundProvider>(
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
      child: Consumer<ClientsRefundProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: ProviderLoadingWidget());
          }

          return provider.filteredClients.isEmpty
              ? const Center(child: Text('No Clients found in this category'))
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemCount: provider.filteredClients.length,
                itemBuilder: (context, index) {
                  final client = provider.filteredClients[index];
                  return _RefundClientListItem(client: client);
                },
              );
        },
      ),
    );
  }
}

// In clients_refund.dart, replace the existing _RefundClientListItem with this one.

class _RefundClientListItem extends StatefulWidget {
  final Map<String, dynamic> client;

  const _RefundClientListItem({required this.client});

  @override
  State<_RefundClientListItem> createState() => _RefundClientListItemState();
}

class _RefundClientListItemState extends State<_RefundClientListItem> {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<ClientsRefundProvider>();
    // The visual selection highlight on tap is removed in favor of showing a dialog.
    // Buttons will handle their own selection context.
    final isRefunded = widget.client['refunded'] == true;

    return Card(
      elevation: 10,
      margin: EdgeInsets.only(bottom: 1.5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        // The tileColor logic is removed as we are no longer visually selecting on tap.
        tileColor: AppColors.whitecolor,
        title: Text(
          widget.client['name']?.toString().toUpperCase() ?? 'N/A',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          'Form No: ${widget.client['form_no'] ?? 'N/A'}',
          style: TextStyle(fontSize: 12.sp, color: Colors.black),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Generate Refund Statement',
              onPressed:
                  () =>
                      isRefunded
                          ? _generateStatement(context)
                          : SupabaseExceptionHandler.showErrorSnackbar(
                            context,
                            'Please mark the client as refunded first.',
                          ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
              color: AppColors.darkbrown,
              onSelected: (value) => _handleMenuSelection(context, value),
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value:
                        isRefunded ? 'Revert to Suspended' : 'Mark as Refunded',
                    child: Text(
                      isRefunded ? 'Revert to Suspended' : 'Mark as Refunded',
                      style: const TextStyle(
                        color: AppColors.whitecolor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        // UPDATED: onTap now shows a details dialog.
        onTap: () {
          _showClientDetailsDialog(context, widget.client);
        },
      ),
    );
  }

  // NEW: Function to show a details dialog for the client.
  void _showClientDetailsDialog(
    BuildContext context,
    Map<String, dynamic> client,
  ) {
    final bool isRefunded = client['refunded'] == true;
    final String status = isRefunded ? 'Refunded' : 'Suspended';
    final Color statusColor = isRefunded ? Colors.green : Colors.orange;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Client Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow(
                  'Name:',
                  client['name']?.toString().toUpperCase() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Form No:',
                  client['form_no']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Membership No:',
                  client['membership_no']?.toString().toUpperCase() ?? 'N/A',
                ),
                _buildDetailRow(
                  'CNIC:',
                  client['cnic_passport_no']?.toString() ?? 'N/A',
                ),
                _buildDetailRow(
                  'Mobile No:',
                  client['mobile_no']?.toString() ?? 'N/A',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Text(
                        'Remarks:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(client['status_remarks']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // NEW: Helper widget to build a row in the details dialog for cleaner code.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _generateStatement(BuildContext context) async {
    final provider = context.read<ClientsRefundProvider>();
    try {
      // First select the client to ensure we have the right one for the PDF.
      // This is important because the provider's state is used in the PDF generation.
      provider.selectClient(widget.client);

      // Then generate the statement.
      await provider.generateRefundStatementPDF(context);
    } catch (e) {
      final error = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, error);
    }
  }

  void _handleMenuSelection(BuildContext context, String value) async {
    final provider = context.read<ClientsRefundProvider>();
    final membershipNo = widget.client['membership_no']?.toString();

    if (membershipNo == null || membershipNo.isEmpty) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Membership number is missing.',
      );
      return;
    }

    final verified = await AdminVerification.showVerificationDialog(
      context: context,
      action: 'Do you want to proceed with this action?',
    );
    if (verified != true) return;
    try {
      if (value == 'Mark as Refunded') {
        await showDialog(
          context: context,
          builder:
              (context) =>
                  RefundDialog(membershipNo: membershipNo, provider: provider),
        );
      } else if (value == 'Revert to Suspended') {
        await provider.revertRefund(membershipNo);
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Member status reverted to suspended.',
        );
      }
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    }
  }
}

// =========================================================================
// NEW: Dialog for refund slip generation (Completely updated)
// =========================================================================
class _RefundSlipDialog extends StatefulWidget {
  const _RefundSlipDialog();

  @override
  State<_RefundSlipDialog> createState() => _RefundSlipDialogState();
}

class _RefundSlipDialogState extends State<_RefundSlipDialog> {
  final _formKey = GlobalKey<FormState>();
  final _membershipNoController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSearching = false;
  bool _isGenerating = false; // <-- State for PDF generation loading
  Map<String, dynamic>? _client;
  Map<String, dynamic>? _refundDetails;
  String? _errorMessage;

  @override
  void dispose() {
    _membershipNoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Button is enabled only when client & refund details are fetched
    final bool canGenerate = _client != null && _refundDetails != null;

    return AlertDialog(
      title: const Text('Generate Refund Slip'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _membershipNoController,
                decoration: InputDecoration(
                  labelText: 'Enter Membership Number',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed:
                        _isSearching || _isGenerating ? null : _searchClient,
                  ),
                ),
                onSubmitted:
                    (_) =>
                        _isSearching || _isGenerating ? null : _searchClient(),
              ),
              const SizedBox(height: 16),
              if (_isSearching) const Center(child: ProviderLoadingWidget()),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              if (canGenerate) _buildClientInfoAndAmountField(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          // Disable cancel button while generating
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Disable button if not ready OR if already generating
          onPressed:
              canGenerate && !_isGenerating
                  ? () => _generateAndSaveSlip(context)
                  : null,
          child:
              _isGenerating
                  ? const SizedBox(
                    // Show a compact loading indicator inside the button
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Generate & Save'),
        ),
      ],
    );
  }

  Widget _buildClientInfoAndAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client Found:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('Name: ${_client!['name'] ?? 'N/A'}'),
        Text(
          'Status: ${_client!['refunded'] == true ? 'Refunded' : 'Not Refunded'}',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Enter Receipt Amount',
            prefixText: 'Rs. ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            if (double.parse(value) <= 0) {
              return 'Amount must be greater than zero';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _searchClient() async {
    final membershipNo = _membershipNoController.text.trim();
    if (membershipNo.isEmpty) {
      setState(() => _errorMessage = 'Please enter a membership number.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _client = null;
      _refundDetails = null;
      _errorMessage = null;
      _amountController.clear();
    });

    try {
      final provider = context.read<ClientsRefundProvider>();
      final clientData = await provider.fetchClientByMembershipNo(membershipNo);

      if (clientData == null || clientData['refunded'] != true) {
        setState(() {
          _errorMessage = 'Client not found or is not in "Refunded" status.';
        });
        return;
      }

      final refundData = await provider.fetchRefundDetails(membershipNo);
      if (refundData == null) {
        setState(() {
          _errorMessage = 'Refund processing data not found for this client.';
        });
        return;
      }

      setState(() {
        _client = clientData;
        _refundDetails = refundData;
      });
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred while searching.');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _generateAndSaveSlip(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Start loading
    setState(() {
      _isGenerating = true;
    });

    final amount = double.parse(_amountController.text.trim());
    final provider = context.read<ClientsRefundProvider>();

    try {
      await provider.generateRefundSlipPDF(
        context: context,
        client: _client!,
        refund: _refundDetails!,
        receiptAmount: amount,
      );

      if (mounted) Navigator.pop(context); // Close dialog on success
    } catch (e) {
      final error = SupabaseExceptionHandler.handleSupabaseError(e);
      if (mounted) SupabaseExceptionHandler.showErrorSnackbar(context, error);
    } finally {
      // Stop loading, ensuring the widget is still mounted
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
