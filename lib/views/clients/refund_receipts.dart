// refund_receipts_screen.dart
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

class RefundReceiptsScreen extends StatelessWidget {
  const RefundReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RefundReceiptsProvider>(
      create: (context) => RefundReceiptsProvider(),
      child: const _RefundReceiptsView(),
    );
  }
}

class _RefundReceiptsView extends StatelessWidget {
  const _RefundReceiptsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(context), body: _buildBody(context));
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Refund Receipts',
        style: GoogleFonts.aBeeZee(fontSize: 18.sp),
      ),
      backgroundColor: AppColors.darkbrown,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
          onPressed: () => context.read<RefundReceiptsProvider>().refreshData(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.rmncolorlight),
      child: Column(
        children: [
          _buildSearchBar(context),
          SizedBox(height: 1.h),
          _buildReceiptsList(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2.h),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Name or Receipt No...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.blackcolor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: AppColors.whitecolor,
        ),
        onChanged:
            (value) =>
                context.read<RefundReceiptsProvider>().updateSearchQuery(value),
      ),
    );
  }

  Widget _buildReceiptsList(BuildContext context) {
    return Expanded(
      child: Consumer<RefundReceiptsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: ProviderLoadingWidget());
          }

          return provider.filteredReceipts.isEmpty
              ? const Center(child: Text('No receipts found'))
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                itemCount: provider.filteredReceipts.length,
                itemBuilder: (context, index) {
                  final receipt = provider.filteredReceipts[index];
                  return _RefundReceiptListItem(receipt: receipt);
                },
              );
        },
      ),
    );
  }
}

class _RefundReceiptListItem extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const _RefundReceiptListItem({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final clientName = receipt['membership_forms']?['name'] ?? 'N/A';
    final membershipNo = receipt['membership_no'] ?? 'N/A';
    final receiptNo = receipt['receipt_no'] ?? 'N/A';
    final amount = receipt['refund_amount'] ?? 0.0;
    final date =
        receipt['generated_date'] != null
            ? DateTime.parse(receipt['generated_date']).toLocal()
            : null;
    final formattedDate =
        date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A';

    return Card(
      elevation: 10,
      margin: EdgeInsets.only(bottom: 1.5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        tileColor: AppColors.whitecolor,
        title: Text(
          clientName.toString().toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt No: $receiptNo',
              style: TextStyle(fontSize: 12.sp, color: Colors.black),
            ),
          ],
        ),
        trailing: Text(
          formattedDate,
          style: TextStyle(fontSize: 10.sp, color: Colors.black),
        ),
        onTap: () => _showReceiptDetails(context, receipt),
      ),
    );
  }

  void _showReceiptDetails(BuildContext context, Map<String, dynamic> receipt) {
    final clientName = receipt['membership_forms']?['name'] ?? 'N/A';
    final cnic = receipt['membership_forms']?['cnic_passport_no'] ?? 'N/A';
    final membershipNo = receipt['membership_no'] ?? 'N/A';
    final receiptNo = receipt['receipt_no'] ?? 'N/A';
    final amount = receipt['refund_amount'] ?? 0.0;
    final date =
        receipt['generated_date'] != null
            ? DateTime.parse(receipt['generated_date']).toLocal()
            : null;
    final formattedDate =
        date != null ? DateFormat('dd/MM/yyyy hh:mm a').format(date) : 'N/A';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Receipt Details',
            style: GoogleFonts.aBeeZee(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  'Membership No:',
                  membershipNo.toString().toUpperCase(),
                ),
                _buildDetailRow('Client Name:', clientName.toString()),
                _buildDetailRow('Receipt No:', receiptNo.toString()),
                _buildDetailRow('Amount:', 'Rs. ${amount.toStringAsFixed(0)}'),
                _buildDetailRow('Date Issued:', formattedDate),
                const SizedBox(height: 16),
                // Container(
                //   decoration: BoxDecoration(
                //     border: Border.all(color: AppColors.darkbrown),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   padding: const EdgeInsets.all(12),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         'Additional Information',
                //         style: GoogleFonts.aBeeZee(
                //           fontSize: 12.sp,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //       const SizedBox(height: 8),
                //       // Add any additional fields you want to display
                //       _buildDetailRow('Payment Method:', 'Bank Transfer'),
                //       _buildDetailRow('Transaction Ref:', 'N/A'),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            // TextButton(
            //   onPressed: () {
            //     // Add functionality to view/print PDF
            //     Navigator.pop(context);
            //   },
            //   child: const Text('View PDF'),
            // ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12.sp))),
        ],
      ),
    );
  }
}
