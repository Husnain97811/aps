import 'package:aps/config/providers/offer_installment_provider.dart';
import 'package:aps/config/view.dart';
import 'package:aps/views/forms/installment_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallmentReceiptScreen extends StatefulWidget {
  const InstallmentReceiptScreen({super.key});

  @override
  _InstallmentReceiptScreenState createState() =>
      _InstallmentReceiptScreenState();
}

class _InstallmentReceiptScreenState extends State<InstallmentReceiptScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final FormControllers _formControllers = FormControllers();

  bool _isSubmitting = false;
  bool _isSaved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateTemporaryNumbers();
  }

  // Clear offer fields when switching to regular mode
  void _clearOfferFields() {
    _formControllers.offerReceivedAmountController.clear();
    _formControllers.offerDiscountAmountController.clear();
  }

  // Clear regular fields when switching to offer mode
  void _clearRegularFields() {
    _formControllers.receivedAmountController.clear();
    _formControllers.discountController.clear();
  }

  Future<void> _generateTemporaryNumbers() async {
    if (!mounted) return;
    try {
      final DateTime now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MMM-dd').format(now);

      // Fetch current user's name
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userResponse =
          await Supabase.instance.client
              .from('profiles')
              .select('full_name')
              .eq('id', currentUser!.id)
              .single();
      final userName =
          userResponse['full_name'] as String? ?? 'Authorized Sign.';

      // Fetch the latest receipt_no from the database
      final response =
          await supabase
              .from('installment_receipts')
              .select('receipt_no')
              .order('receipt_no', ascending: false)
              .limit(1)
              .maybeSingle();

      // Extract the latest receipt_no or use default value
      String latestReceiptNo = (response?['receipt_no']?.toString()) ?? '000';

      int newReceiptNo = int.parse(latestReceiptNo) + 1;
      if (mounted) {
        setState(() {
          _formControllers.receiptNoController.text = newReceiptNo
              .toString()
              .padLeft(3, '0');
          _formControllers.dateController.text = formattedDate;
          _formControllers.authorizedSignatureController.text = userName;
        });
      }
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _formControllers.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Installment Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.normal,
          ),
          padding: EdgeInsets.all(2.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Receipt No.',
                        controller: _formControllers.receiptNoController,
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Installment No.',
                        controller: _formControllers.installmentNoController,
                        enabled: false,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Membership No.',
                        controller: _formControllers.membershipNoController,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fetchMemberDetails,
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 1.8.h,
                                height: 1.8.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                              : Text('Fetch'),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Date',
                        controller: _formControllers.dateController,
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Name',
                        enabled: false,
                        controller: _formControllers.nameController,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: textMembershipFormField(
                        label: 'S/O/D/W of',
                        enabled: false,
                        controller:
                            _formControllers.fatherHusbandNameController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                textMembershipFormField(
                  enabled: false,
                  label: 'Address',
                  controller: _formControllers.addressController,
                  maxLines: 2,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: cnicMembershipFormField(
                        context: context,
                        label: 'CNIC',
                        controllers: _formControllers.cnicControllers,
                        focusNodes: _formControllers.cnicFocusNodes,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Phone No.',
                        enabled: false,
                        controller: _formControllers.mobileNoController,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Late Installments Offer Checkbox
                Consumer<LateInstallmentsOfferProvider>(
                  builder: (context, provider, child) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Beautiful Checkbox
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  provider.isLateInstallmentsOffer
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    provider.isLateInstallmentsOffer
                                        ? Colors.blue
                                        : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: Theme(
                              data: ThemeData(
                                unselectedWidgetColor: Colors.transparent,
                              ),
                              child: Checkbox(
                                value: provider.isLateInstallmentsOffer,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    if (value) {
                                      _clearRegularFields();
                                    } else {
                                      _clearOfferFields();
                                    }
                                    provider.setLateInstallmentsOffer(value);
                                  }
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Installments Offer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Check this if payment is for last installments offer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (provider.isLateInstallmentsOffer)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 2.h),

                // Conditional Amount Fields
                Consumer<LateInstallmentsOfferProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLateInstallmentsOffer) {
                      // Show Offer Amount Fields, hide regular ones
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: textMembershipFormField(
                                  label: 'Offer Paid Amount',
                                  controller:
                                      _formControllers
                                          .offerReceivedAmountController,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: textMembershipFormField(
                                  label: 'Offer Discount',
                                  controller:
                                      _formControllers
                                          .offerDiscountAmountController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return null;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                        ],
                      );
                    } else {
                      // Show Regular Amount Fields, hide offer ones
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: textMembershipFormField(
                                  label: 'Received Amount',
                                  controller:
                                      _formControllers.receivedAmountController,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: textMembershipFormField(
                                  label: 'Discount Amount',
                                  controller:
                                      _formControllers.discountController,
                                  //here set validator to accept null or empty
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return null;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                        ],
                      );
                    }
                  },
                ),

                textMembershipFormField(
                  maxLines: 2,
                  label: 'Amount in Words',
                  controller: _formControllers.amountInWordsController,
                ),
                SizedBox(height: 2.h),

                Row(
                  children: [
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Mode of Payment',
                        controller: _formControllers.modeOfPaymentController,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: textMembershipFormField(
                        label: 'Authorized Signature',
                        controller:
                            _formControllers.authorizedSignatureController,
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                _buildPaymentDescriptionSection(),
                SizedBox(height: 2.h),
                // REMARKS FIELD ADDED HERE
                textRemarksMembershipFormField(
                  label: 'Remarks',
                  controller: _formControllers.remarksController,
                  maxLines: 2,
                ),
                SizedBox(height: 3.2.h),
                if (_isSubmitting) Center(child: CircularProgressIndicator()),
                if (!_isSubmitting && !_isSaved)
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                  ),
                SizedBox(height: 2.6.h),
                if (_isSaved)
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveAsPdf,
                      child: Text('Save as PDF'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this getter to check which fields to save based on mode
  // Corrected _getAmountFieldsToSave method
  Map<String, dynamic> _getAmountFieldsToSave() {
    final provider = context.read<LateInstallmentsOfferProvider>();

    if (provider.isLateInstallmentsOffer) {
      return {
        'received_amount': null, // Store null for regular fields
        'discount': null, // Store null for regular fields
        'offer_received_amount':
            _formControllers.offerReceivedAmountController.text.isEmpty
                ? null
                : _formControllers.offerReceivedAmountController.text,
        'offer_discount_amount':
            _formControllers.offerDiscountAmountController.text.isEmpty
                ? null
                : _formControllers.offerDiscountAmountController.text,
      };
    } else {
      return {
        'received_amount':
            _formControllers.receivedAmountController.text.isEmpty
                ? null
                : _formControllers.receivedAmountController.text,
        'discount':
            _formControllers.discountController.text.isEmpty
                ? null
                : _formControllers.discountController.text,
        'offer_received_amount': null, // Store null for offer fields
        'offer_discount_amount': null, // Store null for offer fields
      };
    }
  }

  Future<int?> getLatestInstallment(String membershipNo) async {
    try {
      // First, try to get all installment numbers
      final response = await supabase
          .from('installment_receipts')
          .select('installment_no')
          .eq('membership_no', membershipNo);

      if (response == null || response.isEmpty) {
        return null;
      }

      // Convert to integers and find max
      int maxInstallment = 0;
      for (final item in response) {
        final installmentStr = item['installment_no']?.toString();
        if (installmentStr != null) {
          final installmentNo = int.tryParse(installmentStr);
          if (installmentNo != null && installmentNo > maxInstallment) {
            maxInstallment = installmentNo;
          }
        }
      }

      return maxInstallment > 0 ? maxInstallment : null;
    } catch (e) {
      print('Error fetching latest installment: $e');
      return null;
    }
  }

  Future<void> _fetchMemberDetails() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    final membershipNo =
        _formControllers.membershipNoController.text.toLowerCase();

    // Preserve the existing authorized signature
    final existingSignature =
        _formControllers.authorizedSignatureController.text;
    try {
      // Fetch member details from membership_forms
      final membershipResponse =
          await supabase
              .from('membership_forms')
              .select(
                'name, father_husband_name, address, cnic_passport_no, mobile_no',
              )
              .eq('membership_no', membershipNo)
              .maybeSingle();

      if (membershipResponse != null) {
        // Restore the authorized signature
        _formControllers.authorizedSignatureController.text = existingSignature;
        // Update form fields
        _formControllers.nameController.text = membershipResponse['name'] ?? '';
        _formControllers.fatherHusbandNameController.text =
            membershipResponse['father_husband_name'] ?? '';
        _formControllers.addressController.text =
            membershipResponse['address'] ?? '';
        String cnic = membershipResponse['cnic_passport_no'] ?? '';
        for (int i = 0; i < cnic.length; i++) {
          if (i < _formControllers.cnicControllers.length) {
            _formControllers.cnicControllers[i].text = cnic[i];
          }
        }

        _formControllers.mobileNoController.text =
            membershipResponse['mobile_no'] ?? '';

        // Fetch latest installment number and calculate next installment
        final latestInstallment = await getLatestInstallment(membershipNo);

        print('$latestInstallment');

        int latestInstallmentNo = latestInstallment ?? 0;
        int newInstallmentNo = latestInstallmentNo + 1;
        _formControllers.installmentNoController.text =
            newInstallmentNo.toString();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Membership number $membershipNo not found. Please verify.',
            ),
          ),
        );
      }
    } catch (error) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(error);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // save data to database
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final supabase = Supabase.instance.client;
    final membershipNo =
        _formControllers.membershipNoController.text.toLowerCase();

    try {
      // 1. Check if membership number exists in membership_forms table and retrieve the record
      final membershipResponse =
          await supabase
              .from('membership_forms')
              .select(
                'membership_no, name, father_husband_name, address, cnic_passport_no, mobile_no',
              )
              .eq('membership_no', membershipNo)
              .maybeSingle();

      if (membershipResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Membership number $membershipNo does not exist. Please verify.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Fetch latest receipt_no
      final response =
          await supabase
              .from('installment_receipts')
              .select('receipt_no')
              .order('receipt_no', ascending: false)
              .limit(1)
              .maybeSingle();

      // Extract latest receipt_no or start at 001
      int latestReceiptNo =
          response != null && response['receipt_no'] != null
              ? response['receipt_no'] as int
              : 1;

      // Increment the receipt number
      int newReceiptNo = latestReceiptNo + 1;

      DateTime now = DateTime.now();
      String formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // fetch current user id and name
      final userId = supabase.auth.currentUser!.id;
      final userName =
          await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', userId)
              .maybeSingle();

      // Get amount fields based on mode
      final amountFields = _getAmountFieldsToSave();

      // Prepare data map for insertion
      Map<String, dynamic> insertData = {
        'receipt_no': newReceiptNo,
        'membership_no': membershipNo.toLowerCase(),
        'installment_no':
            _formControllers.installmentNoController.text.toLowerCase(),
        'date': formattedDate.toLowerCase(),
        'name': membershipResponse['name'].toLowerCase(),
        'father_husband_name':
            membershipResponse['father_husband_name'].toLowerCase(),
        'address': membershipResponse['address'].toLowerCase(),
        'cnic': membershipResponse['cnic_passport_no'].toLowerCase(),
        'mobile_no': membershipResponse['mobile_no'].toLowerCase(),
        'amount_in_words':
            _formControllers.amountInWordsController.text.toLowerCase(),
        'mode_of_payment':
            _formControllers.modeOfPaymentController.text.toLowerCase(),
        'remarks':
            _formControllers.remarksController.text.isNotEmpty
                ? _formControllers.remarksController.text.toLowerCase()
                : null, // Store null for empty remarks
        'authorized_signature':
            _formControllers.authorizedSignatureController.text.toLowerCase(),
        'installment_slips': false,
        'created_by': userName?['full_name'].toLowerCase(),
        'description':
            context
                .read<PaymentDescriptionProvider>()
                .selectedDescription
                .displayName
                .toLowerCase(),
        'special_offer':
            context
                .read<LateInstallmentsOfferProvider>()
                .isLateInstallmentsOffer,
      };

      // Add amount fields
      insertData['received_amount'] = amountFields['received_amount'];
      insertData['discount'] = amountFields['discount'];
      insertData['offer_received_amount'] =
          amountFields['offer_received_amount'];
      insertData['offer_discount_amount'] =
          amountFields['offer_discount_amount'];

      // Remove any null values if you want to avoid sending them
      // (Optional - Supabase will store null for missing keys anyway)
      insertData.removeWhere((key, value) => value == null);

      await supabase.from('installment_receipts').insert(insertData);

      setState(() {
        _isSaved = true;
      });

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Receipt Added successfully!',
      );
      _formControllers.receiptNoController.text = newReceiptNo.toString();
    } catch (error) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(
        'Error Saving Data $error',
      );
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // generate pdf and save on local db
  Future<void> _saveAsPdf() async {
    try {
      final provider = context.read<LateInstallmentsOfferProvider>();
      final isOfferMode = provider.isLateInstallmentsOffer;

      // Build installment map from form data
      final installmentMap = {
        'receipt_no': _formControllers.receiptNoController.text,
        'installment_no': _formControllers.installmentNoController.text,
        'membership_no': _formControllers.membershipNoController.text,
        'date': _formControllers.dateController.text,
        'name': _formControllers.nameController.text,
        'father_husband_name':
            _formControllers.fatherHusbandNameController.text,
        'address': _formControllers.addressController.text,
        'cnic': _formControllers.cnicControllers.map((c) => c.text).join(),
        'mobile_no': _formControllers.mobileNoController.text,
        'amount_in_words': _formControllers.amountInWordsController.text,
        if (_formControllers.remarksController.text.isNotEmpty)
          'remarks': _formControllers.remarksController.text,
        'mode_of_payment': _formControllers.modeOfPaymentController.text,
        'authorized_signature':
            _formControllers.authorizedSignatureController.text,
        'description':
            context
                .read<PaymentDescriptionProvider>()
                .selectedDescription
                .displayName,
        'special_offer': isOfferMode,
      };

      // Set BOTH regular and offer fields, the PDF service will decide which to show
      installmentMap['received_amount'] =
          _formControllers.receivedAmountController.text;
      installmentMap['discount'] = _formControllers.discountController.text;
      installmentMap['offer_received_amount'] =
          _formControllers.offerReceivedAmountController.text;
      installmentMap['offer_discount_amount'] =
          _formControllers.offerDiscountAmountController.text;

      // Generate PDF using service
      final pdfFile = await PdfGenerationService.generateInstallmentPdf(
        installmentMap,
      );

      // Show success and open PDF
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF saved to: ${pdfFile.path}')));
      OpenFile.open(pdfFile.path);

      // Close screen after delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  // widget for payment description
  Widget _buildPaymentDescriptionSection() {
    return Consumer<PaymentDescriptionProvider>(
      builder: (context, provider, _) {
        return FormField<PaymentDescription>(
          validator: (value) {
            return null;
          },
          builder: (formFieldState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Description:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children:
                      PaymentDescription.values.map((desc) {
                        return Expanded(
                          child: RadioListTile<PaymentDescription>(
                            title: Text(desc.displayName),
                            value: desc,
                            groupValue: provider.selectedDescription,
                            onChanged:
                                (value) => provider.setDescription(value!),
                          ),
                        );
                      }).toList(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
