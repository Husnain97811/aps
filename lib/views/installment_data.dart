import 'package:aps/config/view.dart';
import 'package:aps/services/admin_verification_service.dart';
import 'package:aps/views/forms/installment_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Added for provider

class InstallmentData extends StatefulWidget {
  const InstallmentData({super.key});

  @override
  State<InstallmentData> createState() => _InstallmentDataState();
}

class _InstallmentDataState extends State<InstallmentData> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWinnedClients();
  }

  Future<void> _handleRefresh() async {
    // Get the global provider. listen: false is crucial for actions.
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    try {
      // START the full-screen loading overlay.
      // We use `startLoading()` for general actions.
      loadingProvider.startLoading();

      // Perform the refresh by calling the existing fetch logic.
      await _fetchWinnedClients();
    } catch (e) {
      // The fetch method already shows a SnackBar on error.
      print("Refresh action failed: $e");
    } finally {
      // IMPORTANT: Always stop the overlay, even if an error occurred.
      if (mounted) {
        loadingProvider.stopLoading();
      }
    }
  }

  Future<void> _fetchWinnedClients() async {
    try {
      final installmentSlipsResponse = await _supabase
          .from('installment_receipts')
          .select()
          .order('receipt_no', ascending: true);

      if (installmentSlipsResponse.isEmpty) {
        setState(() {
          _clients = [];
          _filteredClients = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _clients = List<Map<String, dynamic>>.from(installmentSlipsResponse);
        _filteredClients = _clients;
        _isLoading = false;
      });
    } catch (e) {
      print(e);

      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error Fetching Receipts $e',
      );
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch data';
      });
    }
  }

  void _searchClients(String query) {
    setState(() {
      _filteredClients =
          _clients.where((client) {
            final formNo = client['receipt_no'].toString().toLowerCase();
            final MembershipNo =
                client['membership_no'].toString().toLowerCase();
            return formNo.contains(query.toLowerCase()) ||
                MembershipNo.contains(query.toLowerCase());
          }).toList();
    });
  }

  // Create the edit dialog function for installment data
  void showEditInstallmentDialog(
    BuildContext context,
    Map<String, dynamic> installment,
  ) async {
    // Verify admin first
    final isVerified = await AdminVerification.showVerificationDialog(
      context: context,
      action: 'edit this installment',
    );

    if (!isVerified) return;

    // Get current user name
    final currentUser =
        await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', _supabase.auth.currentUser!.id)
            .single();

    // Check if it's a special offer
    final isSpecialOffer = installment['special_offer'] == true;

    // Create controllers with initial values for installment fields
    final receiptNo = installment['receipt_no']?.toString() ?? '';
    final membershipNo = installment['membership_no']?.toString() ?? '';

    final nameController = TextEditingController(text: installment['name']);
    final fatherHusbandController = TextEditingController(
      text: installment['father_husband_name'],
    );
    final addressController = TextEditingController(
      text: installment['address'],
    );
    final cnicController = TextEditingController(text: installment['cnic']);
    final mobileController = TextEditingController(
      text: installment['mobile_no'],
    );

    // Determine which amount fields to show based on special_offer
    final amountController = TextEditingController(
      text:
          isSpecialOffer
              ? installment['offer_received_amount']?.toString()
              : installment['received_amount']?.toString(),
    );

    final discountController = TextEditingController(
      text:
          isSpecialOffer
              ? installment['offer_discount_amount']?.toString()
              : installment['discount']?.toString(),
    );

    final wordsController = TextEditingController(
      text: installment['amount_in_words'],
    );
    final modeController = TextEditingController(
      text: installment['mode_of_payment'],
    );
    final remarksController = TextEditingController(
      text: installment['remarks'],
    );
    final dateController = TextEditingController(text: installment['date']);

    // Get description from installment
    final description = installment['description']?.toString() ?? 'Installment';
    final authorizedSignature =
        installment['authorized_signature']?.toString() ??
        currentUser['full_name'];

    // State variables for the dialog
    bool _isUpdated = false;
    Map<String, dynamic> _updatedInstallment = {...installment};

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Edit Installment Details',
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
                      // Receipt No (read-only)
                      buildEditField(
                        'Receipt No',
                        TextEditingController(text: receiptNo),
                        enabled: false,
                      ),
                      // Membership No (read-only)
                      buildEditField(
                        'Membership No',
                        TextEditingController(text: membershipNo),
                        enabled: false,
                      ),
                      buildEditField(
                        'Name',
                        nameController,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        'Father/Husband Name',
                        fatherHusbandController,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        'Address',
                        addressController,
                        maxLines: 3,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        'CNIC/Passport',
                        cnicController,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        'Mobile',
                        mobileController,
                        enabled: !_isUpdated,
                      ),

                      // Show appropriate amount fields based on special_offer
                      buildEditField(
                        isSpecialOffer ? 'Offer Amount' : 'Amount',
                        amountController,
                        isNumber: true,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        isSpecialOffer ? 'Offer Discount' : 'Discount',
                        discountController,
                        isNumber: true,
                        enabled: !_isUpdated,
                      ),

                      buildEditField(
                        'Amount in Words',
                        wordsController,
                        maxLines: 2,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        'Mode of Payment',
                        modeController,
                        enabled: !_isUpdated,
                      ),
                      buildEditField(
                        'Remarks',
                        remarksController,
                        enabled: !_isUpdated,
                      ),
                      if (!_isUpdated)
                        GestureDetector(
                          onTap: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (selectedDate != null) {
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate);
                              setState(() {});
                            }
                          },
                          child: AbsorbPointer(
                            child: buildEditField('Date', dateController),
                          ),
                        )
                      else
                        buildEditField('Date', dateController, enabled: false),
                    ],
                  ),
                ),
                actions: [
                  if (!_isUpdated)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  if (!_isUpdated)
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty) {
                          SupabaseExceptionHandler.showErrorSnackbar(
                            context,
                            'Name is Required',
                          );
                          return;
                        }

                        try {
                          // Prepare update data
                          Map<String, dynamic> updatedInstallment = {
                            'name': nameController.text,
                            'father_husband_name': fatherHusbandController.text,
                            'address': addressController.text,
                            'cnic': cnicController.text,
                            'mobile_no': mobileController.text,
                            'amount_in_words': wordsController.text,
                            'mode_of_payment': modeController.text,
                            'remarks': remarksController.text,
                            'date': dateController.text,
                            'updated_by': currentUser['full_name'].toString(),
                          };

                          // Update amount fields based on special_offer
                          if (isSpecialOffer) {
                            updatedInstallment['offer_received_amount'] =
                                amountController.text.trim().isNotEmpty
                                    ? amountController.text.trim()
                                    : null;
                            updatedInstallment['offer_discount_amount'] =
                                discountController.text.trim().isNotEmpty
                                    ? discountController.text.trim()
                                    : null;
                            // Clear regular amount fields
                            updatedInstallment['received_amount'] = null;
                            updatedInstallment['discount'] = null;
                          } else {
                            updatedInstallment['received_amount'] =
                                amountController.text.trim().isNotEmpty
                                    ? amountController.text.trim()
                                    : null;
                            updatedInstallment['discount'] =
                                discountController.text.trim().isNotEmpty
                                    ? discountController.text.trim()
                                    : null;
                            // Clear offer amount fields
                            updatedInstallment['offer_received_amount'] = null;
                            updatedInstallment['offer_discount_amount'] = null;
                          }

                          // Update in database
                          await _supabase
                              .from('installment_receipts')
                              .update(updatedInstallment)
                              .eq('receipt_no', installment['receipt_no']);

                          // Update state with complete data
                          setState(() {
                            _isUpdated = true;
                            _updatedInstallment = {
                              ..._updatedInstallment,
                              ...updatedInstallment,
                              'receipt_no': receiptNo,
                              'membership_no': membershipNo,
                              'description': description,
                              'authorized_signature': authorizedSignature,
                              'special_offer': isSpecialOffer,
                            };
                          });

                          // Refresh installment list
                          await _fetchWinnedClients();

                          if (context.mounted) {
                            SupabaseExceptionHandler.showSuccessSnackbar(
                              context,
                              'Installment updated successfully',
                            );
                          }
                        } catch (e) {
                          print('Error updating installment: $e');
                          if (context.mounted) {
                            SupabaseExceptionHandler.showErrorSnackbar(
                              context,
                              'Error Updating Installment $e',
                            );
                          }
                        }
                      },
                      child: Text('Save Changes'),
                    ),

                  if (_isUpdated)
                    ElevatedButton(
                      onPressed: () async {
                        final loadingProvider = Provider.of<LoadingProvider>(
                          context,
                          listen: false,
                        );

                        // Close the dialog first
                        Navigator.pop(context);

                        try {
                          loadingProvider.startPdfLoading();

                          // CRITICAL FIX: Pass BOTH amount fields with proper values
                          final bool isSpecialOffer =
                              _updatedInstallment['special_offer'] ?? false;

                          // Get the correct amount values based on special_offer
                          final String mainAmount =
                              isSpecialOffer
                                  ? (_updatedInstallment['offer_received_amount']
                                          ?.toString() ??
                                      '')
                                  : (_updatedInstallment['received_amount']
                                          ?.toString() ??
                                      '');

                          final String discountAmount =
                              isSpecialOffer
                                  ? (_updatedInstallment['offer_discount_amount']
                                          ?.toString() ??
                                      '')
                                  : (_updatedInstallment['discount']
                                          ?.toString() ??
                                      '');

                          // Prepare complete data for PDF generation
                          final Map<String, dynamic> pdfData = {
                            'receipt_no':
                                _updatedInstallment['receipt_no']?.toString() ??
                                '',
                            'installment_no':
                                _updatedInstallment['installment_no']
                                    ?.toString() ??
                                '',
                            'membership_no':
                                _updatedInstallment['membership_no']
                                    ?.toString() ??
                                '',
                            'date':
                                _updatedInstallment['date']?.toString() ?? '',
                            'name':
                                _updatedInstallment['name']?.toString() ?? '',
                            'father_husband_name':
                                _updatedInstallment['father_husband_name']
                                    ?.toString() ??
                                '',
                            'address':
                                _updatedInstallment['address']?.toString() ??
                                '',
                            'cnic':
                                _updatedInstallment['cnic']?.toString() ?? '',
                            'mobile_no':
                                _updatedInstallment['mobile_no']?.toString() ??
                                '',

                            // ✅ CRITICAL: Pass BOTH sets of fields with correct values
                            'received_amount': isSpecialOffer ? '' : mainAmount,
                            'discount': isSpecialOffer ? '' : discountAmount,
                            'offer_received_amount':
                                isSpecialOffer ? mainAmount : '',
                            'offer_discount_amount':
                                isSpecialOffer ? discountAmount : '',

                            'amount_in_words':
                                _updatedInstallment['amount_in_words']
                                    ?.toString() ??
                                '',
                            'mode_of_payment':
                                _updatedInstallment['mode_of_payment']
                                    ?.toString() ??
                                '',
                            'remarks':
                                _updatedInstallment['remarks']?.toString() ??
                                '',
                            'authorized_signature':
                                _updatedInstallment['authorized_signature']
                                    ?.toString() ??
                                authorizedSignature,
                            'description':
                                _updatedInstallment['description']
                                    ?.toString() ??
                                description,
                            'special_offer': isSpecialOffer,
                          };

                          print(
                            'PDF Data to generate: ${pdfData.keys.toList()}',
                          );
                          print('Receipt No: ${pdfData['receipt_no']}');
                          print('Name: ${pdfData['name']}');
                          print('Main Amount: $mainAmount');
                          print('Special Offer: $isSpecialOffer');

                          final pdfFile =
                              await PdfGenerationService.generateInstallmentPdf(
                                pdfData,
                              );

                          // Use a global context or show success differently
                          // Since context is from dialog (now closed), we need another approach
                          _showPdfSuccessNotification(pdfFile.path);
                        } catch (e) {
                          print('Error generating PDF: $e');
                          _showPdfErrorNotification('Error Generating PDF: $e');
                        } finally {
                          loadingProvider.stopPdfLoading();
                        }
                      },
                      child: Text('Save as PDF'),
                    ),

                  if (_isUpdated)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                backgroundColor: AppColors.whitecolor,
              );
            },
          ),
    );
  }

  void _showPdfSuccessNotification(String filePath) {
    // You can use a GlobalKey or other method
    // For now, just print or use a different approach
    print('PDF saved to: $filePath');
    OpenFile.open(filePath);
  }

  void _showPdfErrorNotification(String error) {
    print('PDF Error: $error');
    // You might want to use a notification plugin or other method
  }

  // Helper widget for edit fields
  Widget buildEditField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
      ),
    );
  }

  // Function to show delete confirmation dialog
  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> client,
  ) async {
    // Verify admin first
    final isVerified = await AdminVerification.showVerificationDialog(
      context: context,
      action: 'delete this installment',
    );

    if (!isVerified) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete receipt ${client['receipt_no']}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Close confirmation dialog
                  await _deleteInstallment(context, client);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // Function to delete an installment
  Future<void> _deleteInstallment(
    BuildContext context,
    Map<String, dynamic> client,
  ) async {
    try {
      // Show loading indicator
      setState(() => _isLoading = true);

      // Delete from database
      await _supabase
          .from('installment_receipts')
          .delete()
          .eq('receipt_no', client['receipt_no']);

      // Refresh the list
      await _fetchWinnedClients();

      if (context.mounted) {
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Receipt deleted successfully',
        );
      }
    } catch (e) {
      print(e);

      if (context.mounted) {
        SupabaseExceptionHandler.showErrorSnackbar(
          context,
          'Error Deleting Receipt $e',
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void showCustomClientDetailsDialog(
    BuildContext context,
    Map<String, dynamic> client,
  ) async {
    // Inside the PDF button onPressed:
    final bool isSpecialOffer = client['special_offer'] == true;

    final Map<String, dynamic> pdfData = {
      'receipt_no': client['receipt_no']?.toString() ?? '',
      // ... other fields
      'received_amount':
          isSpecialOffer ? '' : (client['received_amount']?.toString() ?? ''),
      'discount': isSpecialOffer ? '' : (client['discount']?.toString() ?? ''),
      'offer_received_amount':
          isSpecialOffer
              ? (client['offer_received_amount']?.toString() ?? '')
              : '',
      'offer_discount_amount':
          isSpecialOffer
              ? (client['offer_discount_amount']?.toString() ?? '')
              : '',
      'special_offer': isSpecialOffer,
    };

    final pdfFile = await PdfGenerationService.generateInstallmentPdf(pdfData);
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12.sp,
                color: AppColors.textcolor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: AppColors.blackcolor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Receipts', style: GoogleFonts.aBeeZee(fontSize: 18.sp)),
          backgroundColor: AppColors.darkbrown,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
              onPressed: _handleRefresh,
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.rmncolorlight),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(2.h),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Receipt No or Membership No....',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.blackcolor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: AppColors.whitecolor,
                  ),
                  onChanged: _searchClients,
                ),
              ),
              Expanded(
                child:
                    _isLoading
                        ? Center(child: ProviderLoadingWidget())
                        : _filteredClients.isEmpty
                        ? const Center(child: Text(' No Data found'))
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          itemCount: _filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = _filteredClients[index];
                            return Card(
                              elevation: 10,
                              color: Colors.white,
                              margin: EdgeInsets.only(bottom: 1.5.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // IconButton(
                                    //   onPressed:
                                    //       () => showCustomClientDetailsDialog(
                                    //         client,
                                    //       ),
                                    //   icon: Icon(Icons.visibility),
                                    // ),
                                    IconButton(
                                      onPressed:
                                          () => showEditInstallmentDialog(
                                            context,
                                            client,
                                          ),
                                      icon: Icon(Icons.edit),
                                    ),
                                    IconButton(
                                      onPressed:
                                          () => _showDeleteConfirmation(
                                            context,
                                            client,
                                          ),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  client['name'].toString().toUpperCase() ??
                                      'null',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Receipt No: ${client['receipt_no'] ?? 'null'}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.blackcolor,
                                  ),
                                ),
                                onTap:
                                    () => showCustomClientDetailsDialog(
                                      context,
                                      client,
                                    ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'addInstallment',
          backgroundColor: AppColors.buttoncolor,
          onPressed:
              () =>
                  Navigator.pushNamed(context, RouteNames.installmentreceipts),
          child: const Icon(Icons.add, color: AppColors.whitecolor),
        ),
      ),
    );
  }
}
