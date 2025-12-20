import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

class MembershipFormScreen extends StatefulWidget {
  final bool editMode;
  final String? membershipNo;

  const MembershipFormScreen({
    super.key,
    this.editMode = false,
    this.membershipNo,
  });

  static Route route(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;
    return MaterialPageRoute(
      builder:
          (context) => MembershipFormScreen(
            editMode: args?['editMode'] ?? false,
            membershipNo: args?['membershipNo'],
          ),
    );
  }

  @override
  _MembershipFormScreenState createState() => _MembershipFormScreenState();
}

class _MembershipFormScreenState extends State<MembershipFormScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  FormControllers _formControllers = FormControllers();

  bool _isSubmitting = false;
  bool _isSaved = false;
  bool _isSpecialCategory = false;

  String formNo = '101';
  String membershipNo = 'APS-5M-1001';

  @override
  void initState() {
    super.initState();
    _resetFormState(); // Reset form state when initializing

    if (widget.editMode && widget.membershipNo != null) {
      _loadExistingData(widget.membershipNo!);
    } else {
      _generateTemporaryNumbers();
    }
  }

  /// function to dispose everything after form edit
  void _resetFormState() {
    _formControllers = FormControllers(); // Reinitialize form controllers
    context.read<PaymentPlanProvider>().setSelectedPlan(
      null,
    ); // Reset payment plan
    context.read<DealerProvider>().clearDealerData(); // Clear dealer data
  }
  //----------------------------- function to LOAD DATA for edit membership form---------------------------------------

  Future<void> _loadExistingData(String membershipNo) async {
    try {
      final response =
          await supabase
              .from('membership_forms')
              .select('*, installment_receipts(*)')
              .eq('membership_no', membershipNo)
              .single();

      // Populate read-only fields
      _formControllers.formNoController.text =
          response['form_no']?.toString() ?? '';
      _formControllers.membershipNoController.text =
          response['membership_no'] ?? '';
      _formControllers.dateController.text = response['date'] ?? '';
      _formControllers.projectController.text = response['project'] ?? '';

      // Populate other fields
      _formControllers.nameController.text = response['name'] ?? '';
      _formControllers.fatherHusbandNameController.text =
          response['father_husband_name'] ?? '';
      _formControllers.addressController.text = response['address'] ?? '';
      _formControllers.mobileNoController.text = response['mobile_no'] ?? '';
      _formControllers.ageController.text = response['age']?.toString() ?? '';
      _formControllers.nokNameController.text = response['nok_name'] ?? '';
      _formControllers.nokFatherHusbandNameController.text =
          response['nok_father_husband_name'] ?? '';
      _formControllers.nokAddressController.text =
          response['nok_address'] ?? '';
      _formControllers.nokMobileController.text =
          response['nok_mobile_no'] ?? '';
      _formControllers.relationController.text = response['relation'] ?? '';
      _formControllers.monthlyInstallmentController.text =
          response['monthly_installment']?.toString() ?? '';
      _formControllers.halfYearInstallmentController.text =
          response['halfYear_Installment']?.toString() ?? '';
      _formControllers.developmentChargesController.text =
          response['development_charges']?.toString() ?? '';
      _formControllers.costOfLandController.text =
          response['cost_of_land']?.toString() ?? '';

      // Load additional fields if they exist
      _formControllers.plotNoController.text =
          response['plot_no']?.toString() ?? '';
      // To this (keep full text value): show decimal values also like 3.5 etc
      _formControllers.plotSizeController.text =
          response['plot_size']?.toString() ?? '';
      _formControllers.discountController.text =
          response['discount']?.toString() ?? '0';
      // Load category data
      _formControllers.categoryController.text =
          response['category']?.toString() ?? '';
      _formControllers.isSpecialController.text =
          response['is_special']?.toString() ?? 'false';
      _formControllers.specialTypeController.text =
          response['special_type']?.toString() ?? '';
      _formControllers.additionalChargesController.text =
          response['additional_charges']?.toString() ?? '';

      _isSpecialCategory = response['is_special'] == true;
      _formControllers.downPaymentController.text =
          response['downpayment']?.toString() ?? '';

      final cnic = response['cnic_passport_no']?.toString() ?? '';
      if (cnic.isNotEmpty && cnic.length == 13) {
        for (int i = 0; i < 13; i++) {
          _formControllers.cnicControllers[i].text = cnic[i];
        }
      } else {}

      // Repeat for NOK CNIC
      final nokCnic = response['nok_cnic_passport_no']?.toString() ?? '';
      if (nokCnic.isNotEmpty && nokCnic.length == 13) {
        for (int i = 0; i < 13; i++) {
          _formControllers.nokCnicControllers[i].text = nokCnic[i];
        }
      } else {}

      // Set payment plan
      final paymentPlan = response['payment_plan'];
      if (paymentPlan == 'H.Y Installment Plan') {
        context.read<PaymentPlanProvider>().setSelectedPlan(
          PaymentPlan.hyInstallment,
        );
      } else if (paymentPlan == 'Simple Plan') {
        context.read<PaymentPlanProvider>().setSelectedPlan(
          PaymentPlan.simplePlan,
        );
      } else if (paymentPlan == 'Cash') {
        context.read<PaymentPlanProvider>().setSelectedPlan(PaymentPlan.cash);
      }
      // Handle Dealer Data
      final dlNo = response['dl_no']?.toString() ?? '';

      if (dlNo.isNotEmpty) {
        _formControllers.dlNoController.text = dlNo;
        context.read<DealerProvider>().fetchDealer(dlNo); // Fetch dealer info
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dealer not found')));
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(
        'Error loading data',
      );
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    }
  }

  //render generated values before submission
  Future<void> _generateTemporaryNumbers() async {
    if (widget.editMode) {
      return; // Do not generate temporary numbers in edit mode
    }
    if (!mounted) return;
    final supabase = Supabase.instance.client;

    try {
      final DateTime now = DateTime.now();
      final String formattedDate = DateFormat('yyyy-MMM-dd').format(now);
      // Fetch the latest form_no from the database

      final response =
          await supabase
              .from('membership_forms')
              .select('form_no')
              .order('form_no', ascending: false)
              .limit(1)
              .maybeSingle();

      // Extract the latest form_no or use default value
      int latestFormNo = (response?['form_no'] as int?) ?? 100;

      int newFormNo = latestFormNo + 1;
      String newMembershipNo = 'APS-5M-${900 + newFormNo}';

      if (mounted) {
        // Ensure controllers are initialized
        setState(() {
          _formControllers.formNoController.text = newFormNo.toString();
          _formControllers.membershipNoController.text = newMembershipNo;
          _formControllers.projectController.text = 'Al-Imran-Garden';
          _formControllers.dateController.text = formattedDate;
        });
      }
    } catch (error) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(
        'Error generating temporary numbers',
      );
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);

      // print('Error generating temporary numbers: $error');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _formControllers.dispose();
    context.read<PaymentPlanProvider>().dispose();
    context.read<DealerProvider>().dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('full build membershiop form');
    final isEditMode = widget.editMode;
    final hasPlotData =
        _formControllers.plotNoController.text.isNotEmpty ||
        _formControllers.specialCategoryController.text.isNotEmpty ||
        _formControllers.additionalChargesController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('Membership Form')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.normal,
        ),
        padding: EdgeInsets.all(2.w),
        // accept data for submiting and validation
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Form No.',
                      controller: _formControllers.formNoController,
                      enabled: false,
                    ),
                  ),
                  SizedBox(width: 4.w),
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
                      label: 'Membership No.',
                      enabled: false,
                      controller: _formControllers.membershipNoController,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Project',
                      controller: _formControllers.projectController,
                      initialvalue: 'AL-IMRAN GARDEN',
                      enabled: false,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              textMembershipFormField(
                label: 'Name',
                controller: _formControllers.nameController,
              ),
              SizedBox(height: 2.h),
              textMembershipFormField(
                label: 'Father/Husband Name',
                controller: _formControllers.fatherHusbandNameController,
              ),
              SizedBox(height: 2.h),
              textMembershipFormField(
                label: 'Permanent Address',
                controller: _formControllers.addressController,
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Mobile No.',
                      controller: _formControllers.mobileNoController,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Age',
                      controller: _formControllers.ageController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              cnicMembershipFormField(
                context: context,
                label: 'CNIC / Passport No.',
                controllers: _formControllers.cnicControllers,
                focusNodes: _formControllers.cnicFocusNodes,
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '------------------------------------------------------------------------------------------',
                ),
              ),
              SizedBox(height: 5.h),
              textMembershipFormField(
                label: 'N.O.K Name',
                controller: _formControllers.nokNameController,
              ),
              SizedBox(height: 2.h),
              textMembershipFormField(
                label: 'Father/Husband Name',
                controller: _formControllers.nokFatherHusbandNameController,
              ),
              SizedBox(height: 2.h),
              textMembershipFormField(
                label: 'Permanent Address',
                controller: _formControllers.nokAddressController,
                maxLines: 2,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Mobile No.',
                      controller: _formControllers.nokMobileController,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Relation.',
                      controller: _formControllers.relationController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.5.h),
              cnicMembershipFormField(
                context: context,
                label: 'CNIC / Passport No.',
                controllers: _formControllers.nokCnicControllers,
                focusNodes: _formControllers.nokCnicFocusNodes,
              ),
              SizedBox(height: 5.h),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '------------------------------------------------------------------------------------------',
                ),
              ),
              SizedBox(height: 5.h),
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Monthly Installment',
                      controller: _formControllers.monthlyInstallmentController,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Half Year Insta.',
                      controller:
                          _formControllers.halfYearInstallmentController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Development Charges',
                      controller: _formControllers.developmentChargesController,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Cost of Land',
                      controller: _formControllers.costOfLandController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // New Row for Downpayment
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Downpayment',
                      controller: _formControllers.downPaymentController,
                    ),
                  ),
                  SizedBox(width: 4.w),

                  Expanded(
                    child: textMembershipFormField(
                      label: 'Plot Size(M)',
                      controller: _formControllers.plotSizeController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // New Row for Discount
              Row(
                children: [
                  Expanded(
                    child: textMembershipFormField(
                      label: 'Discount',
                      controller: _formControllers.discountController,
                    ),
                  ),
                  SizedBox(width: 4.w),

                  Expanded(child: SizedBox()),
                ],
              ),
              SizedBox(height: 2.h),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Category*'),
                value:
                    _formControllers.categoryController.text.isNotEmpty
                        ? _formControllers.categoryController.text
                        : null,
                items: const [
                  DropdownMenuItem(
                    value: 'Commercial',
                    child: Text('Commercial'),
                  ),
                  DropdownMenuItem(
                    value: 'Residential',
                    child: Text('Residential'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _formControllers.categoryController.text = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select category';
                  }
                  return null;
                },
              ),

              // Special Category Checkbox
              CheckboxListTile(
                title: Text("Special Category"),
                value: _isSpecialCategory,
                onChanged: (bool? value) {
                  setState(() {
                    _isSpecialCategory = value!;
                    if (!value) {
                      _formControllers.specialTypeController.clear();
                      _formControllers.additionalChargesController.clear();
                    }
                  });
                },
              ),

              // Special Category Fields
              if (_isSpecialCategory) ...[
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Special Type*'),
                  value:
                      _formControllers.specialTypeController.text.isNotEmpty
                          ? _formControllers.specialTypeController.text
                          : null,
                  items: const [
                    DropdownMenuItem(
                      value: 'Park Face',
                      child: Text('Park Face'),
                    ),
                    DropdownMenuItem(value: 'Corner', child: Text('Corner')),
                    DropdownMenuItem(
                      value: 'Main Road',
                      child: Text('Main Road'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _formControllers.specialCategoryController.text = value!;
                    });
                  },
                  validator: (value) {
                    if (_isSpecialCategory &&
                        (value == null || value.isEmpty)) {
                      return 'Please select type';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 2.h),
                TextFormField(
                  controller: _formControllers.additionalChargesController,
                  decoration: InputDecoration(
                    labelText: 'Additional Charges*',
                    suffixText: 'PKR',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isSpecialCategory) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter charges';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid amount';
                      }
                    }
                    return null;
                  },
                ),
              ],

              // Payment plans
              SizedBox(height: 5.h),
              Text(
                'Select Payment Plan:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Consumer<PaymentPlanProvider>(
                builder: (context, paymentPlanProvider, _) {
                  return Column(
                    children: [
                      RadioListTile<PaymentPlan>(
                        title: Text('H.Y Installment Plan'),
                        value: PaymentPlan.hyInstallment,
                        groupValue: paymentPlanProvider.selectedPlan,
                        onChanged: (PaymentPlan? value) {
                          paymentPlanProvider.setSelectedPlan(value);
                        },
                      ),
                      RadioListTile<PaymentPlan>(
                        title: Text('Simple Plan'),
                        value: PaymentPlan.simplePlan,
                        groupValue: paymentPlanProvider.selectedPlan,
                        onChanged: (PaymentPlan? value) {
                          paymentPlanProvider.setSelectedPlan(value);
                        },
                      ),
                      RadioListTile<PaymentPlan>(
                        title: Text('Cash'),
                        value: PaymentPlan.cash,
                        groupValue: paymentPlanProvider.selectedPlan,
                        onChanged: (PaymentPlan? value) {
                          paymentPlanProvider.setSelectedPlan(value);
                        },
                      ),
                    ],
                  );
                },
              ),

              // DEALER SECTION

              // Add this divider line
              Divider(thickness: 2, color: Colors.grey[400], height: 30),

              // Add the selection mark button and fields
              // 2. Updated Form Widget
              Consumer<DealerProvider>(
                builder: (context, dealerProvider, _) {
                  return Column(
                    children: [
                      // Dealer Reference Toggle
                      CheckboxListTile(
                        title: Text("Add Dealer Reference"),
                        value: dealerProvider.dlNo != null,
                        onChanged: (value) {
                          if (value == false) {
                            dealerProvider.clearDealerData();
                          }
                        },
                      ),

                      // Fetch Dealers Button
                      ElevatedButton(
                        onPressed: () async {
                          // await dealerProvider.isLoading;

                          await dealerProvider.fetchAllDealers();
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Select Dealer'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: DealerListDialog(
                                      dealerProvider: dealerProvider,
                                    ),
                                  ),
                                ),
                          );
                        },
                        child:
                            dealerProvider.isLoading
                                ? CircularProgressIndicator()
                                : Text('Fetch Dealers List'),
                      ),
                      SizedBox(height: 8.sp),

                      // Dealer Information Display
                      if (dealerProvider.dlNo != null) ...[
                        ListTile(
                          tileColor: AppColors.darkbrown,
                          title: Text(
                            'Dealer Name: ${dealerProvider.dealerInfo['name'] ?? 'N/A'}',
                          ),
                          subtitle: Text(
                            'DL Number: ${dealerProvider.dlNo ?? 'N/A'}',
                          ),
                        ),
                        CheckboxListTile(
                          title: Text("Reference Verified"),
                          value: dealerProvider.refStatus,
                          onChanged: null,
                        ),
                      ],
                    ],
                  );
                },
              ),
              // Add another divider
              Divider(thickness: 2, color: Colors.grey[400], height: 30),
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
    );
  }

  // functin to update data to database
  Future<void> _updateMembership(String membershipNo) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final paymentPlan = context.read<PaymentPlanProvider>().selectedPlan;
      final dealerProvider = context.read<DealerProvider>();

      final cnic =
          _formControllers.cnicControllers
              .map((controller) => controller.text)
              .join();
      final nokCnic =
          _formControllers.nokCnicControllers
              .map((controller) => controller.text)
              .join();

      final formData = {
        'name': _formControllers.nameController.text,
        'father_husband_name':
            _formControllers.fatherHusbandNameController.text,
        'address': _formControllers.addressController.text,
        'mobile_no': _formControllers.mobileNoController.text,
        'age': _formControllers.ageController.text,
        'cnic_passport_no': cnic,
        'nok_name': _formControllers.nokNameController.text,
        'nok_father_husband_name':
            _formControllers.nokFatherHusbandNameController.text,
        'nok_address': _formControllers.nokAddressController.text,
        'nok_mobile_no': _formControllers.nokMobileController.text,
        'relation': _formControllers.relationController.text,
        'nok_cnic_passport_no': nokCnic,
        'monthly_installment':
            _formControllers.monthlyInstallmentController.text,
        'halfYear_Installment':
            _formControllers.halfYearInstallmentController.text,
        'development_charges':
            _formControllers.developmentChargesController.text,
        'cost_of_land': _formControllers.costOfLandController.text,
        'payment_plan': _getPaymentPlanString(paymentPlan),
        'dl_no': dealerProvider.dlNo,
        'plot_no': _formControllers.plotNoController.text,
        'plot_size': _formControllers.plotSizeController.text,
        'discount': _formControllers.discountController.text,
        'special_category': _formControllers.specialCategoryController.text,
        'additional_charges':
            _formControllers.additionalChargesController.text.isNotEmpty
                ? double.tryParse(
                  _formControllers.additionalChargesController.text,
                )
                : null,
        'dealer_cnic': dealerProvider.dealerInfo['cnic'],
        'rebate1': dealerProvider.dealerInfo['rebate1'],
        'rebate2': dealerProvider.dealerInfo['rebate2'],
        'rebate3': dealerProvider.dealerInfo['rebate3'],
        'rebate4': dealerProvider.dealerInfo['rebate4'],
        'rebate5': dealerProvider.dealerInfo['rebate5'],
      };

      await supabase
          .from('membership_forms')
          .update(formData)
          .eq('membership_no', membershipNo);

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Client updated successfully!',
      );
      Navigator.pop(context); // Close the form after successful update
      print(_formControllers.discountController);
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _getPaymentPlanString(PaymentPlan? plan) {
    switch (plan) {
      case PaymentPlan.hyInstallment:
        return 'H.Y Installment Plan';
      case PaymentPlan.simplePlan:
        return 'Simple Plan';
      case PaymentPlan.cash:
        return 'Cash';
      default:
        return 'Not Selected';
    }
  }

  // save data to database

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final paymentPlan = context.read<PaymentPlanProvider>().selectedPlan;
      final dealerProvider = context.read<DealerProvider>();

      final cnic =
          _formControllers.cnicControllers
              .map((controller) => controller.text)
              .join();
      final nokCnic =
          _formControllers.nokCnicControllers
              .map((controller) => controller.text)
              .join();

      final userId = supabase.auth.currentUser!.id;
      final userName =
          await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', userId)
              .maybeSingle();

      // Base form data
      final formData = {
        'name': _formControllers.nameController.text,
        'father_husband_name':
            _formControllers.fatherHusbandNameController.text,
        'address': _formControllers.addressController.text,
        'mobile_no': _formControllers.mobileNoController.text,
        'age': _formControllers.ageController.text,
        'cnic_passport_no': cnic,
        'nok_name': _formControllers.nokNameController.text,
        'nok_father_husband_name':
            _formControllers.nokFatherHusbandNameController.text,
        'nok_address': _formControllers.nokAddressController.text,
        'nok_mobile_no': _formControllers.nokMobileController.text,
        'relation': _formControllers.relationController.text,
        'nok_cnic_passport_no': nokCnic,
        'monthly_installment':
            _formControllers.monthlyInstallmentController.text,
        'halfYear_Installment':
            _formControllers.halfYearInstallmentController.text,
        'development_charges':
            _formControllers.developmentChargesController.text,
        'cost_of_land': _formControllers.costOfLandController.text,
        'downpayment': _formControllers.downPaymentController.text,
        'category': _formControllers.categoryController.text,
        'plot_size': _formControllers.plotSizeController.text,
        'discount': _formControllers.discountController.text,
        'is_special': _isSpecialCategory,
        'special_category':
            _isSpecialCategory
                ? _formControllers.specialCategoryController.text
                : null,
        'additional_charges':
            _isSpecialCategory
                ? double.tryParse(
                  _formControllers.additionalChargesController.text,
                )
                : null,

        'payment_plan': _getPaymentPlanString(paymentPlan),
        'dl_no': dealerProvider.dlNo,
        'ref': dealerProvider.refStatus,
        // 'ref': dealerProvider.dlNo.isNotEmpty ? 'ref': dealerProvider.refStatus ,
        'dealer_cnic': dealerProvider.dealerInfo['cnic'],
        'rebate1': dealerProvider.dealerInfo['rebate1'],
        'rebate2': dealerProvider.dealerInfo['rebate2'],
        'rebate3': dealerProvider.dealerInfo['rebate3'],
        'rebate4': dealerProvider.dealerInfo['rebate4'],
        'rebate5': dealerProvider.dealerInfo['rebate5'],
        'updated_by': userName?['full_name'] ?? 'Unknown User',
      };

      // Add additional fields only in edit mode if they exist
      if (widget.editMode) {
        if (_formControllers.plotNoController.text.isNotEmpty) {
          formData['plot_no'] = _formControllers.plotNoController.text;
        }
        if (_formControllers.specialCategoryController.text.isNotEmpty) {
          formData['special_category'] =
              _formControllers.specialCategoryController.text;
        }
        if (_formControllers.additionalChargesController.text.isNotEmpty) {
          formData['additional_charges'] =
              double.tryParse(
                _formControllers.additionalChargesController.text,
              ) ??
              0.0;
        }
        //(validate as double but store as string):
        final plotSize = _formControllers.plotSizeController.text;
        if (plotSize.isNotEmpty) {
          if (double.tryParse(plotSize) == null) {
            // Add validation error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid plot size number format')),
            );
            return;
          }
        }
        formData['plot_size'] = plotSize;

        formData['discount'] =
            int.tryParse(_formControllers.discountController.text) ?? '';
      }

      if (widget.editMode && widget.membershipNo != null) {
        // Update existing membership
        await supabase
            .from('membership_forms')
            .update(formData)
            .eq('membership_no', widget.membershipNo!);

        // Show PDF button after successful update
        setState(() => _isSaved = true);

        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Client updated successfully!',
        );

        // Navigator.pop(context); // Close the form after successful update
      } else {
        //  ---------------------------  Create new membership   -----------------------------
        final response =
            await supabase
                .from('membership_forms')
                .select('form_no')
                .order('form_no', ascending: false)
                .limit(1)
                .maybeSingle();

        //fetch current user name from profiles table using current user id
        final userId = supabase.auth.currentUser!.id;
        final userName =
            await supabase
                .from('profiles')
                .select('full_name')
                .eq('id', userId)
                .maybeSingle();

        int latestFormNo = (response?['form_no'] as int?) ?? 100;
        int newFormNo = latestFormNo + 1;
        String newMembershipNo = 'APS-5M-${900 + newFormNo}';

        DateTime now = DateTime.now();
        String formattedDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        await supabase.from('membership_forms').insert({
          ...formData,
          'form_no': newFormNo,
          'date': formattedDate,
          'membership_no': newMembershipNo.toLowerCase(),
          'project': 'al_imran_garden',
          'suspended': false,
          'winned': false,
          'created_by': userName?['full_name'] ?? 'Unknown User',
        });

        setState(() {
          _isSaved = true;
        });

        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Client added successfully!',
        );

        // Update the controllers with the latest values
        _formControllers.formNoController.text = newFormNo.toString();
        _formControllers.membershipNoController.text = newMembershipNo;
      }
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // generate pdf and save on local db

  Future<void> _saveAsPdf() async {
    try {
      DateTime now = DateTime.now();
      String formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.legal,
          margin: const pw.EdgeInsets.symmetric(vertical: 20),
          build: (pw.Context context) {
            return pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 17),
              child: pw.Container(
                // width: Adaptive.w(46),
                width: 660,
                // color: PdfColors.red,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 91),
                    // pw.SizedBox(height: Adaptive.h(17)),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'Membership Form',
                        style: pw.TextStyle(
                          fontSize: 22.52,
                          // fontSize: 15.5.sp,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 0.3.h),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'Apna Plot Scheme',
                        style: pw.TextStyle(
                          fontSize: 14.16,
                          // fontSize: 12.5.sp,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Row(
                      // mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildLabeledField(
                          'Form No.',
                          _formControllers.formNoController.text.toUpperCase(),
                          205,
                          // Adaptive.w(16.5),
                        ),
                        pw.SizedBox(width: 60),

                        // pw.SizedBox(width: Adaptive.w(5.1)),
                        _buildLabeledField(
                          'Date.',
                          formattedDate,
                          231.2,
                          // Adaptive.w(18.4),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      // mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildLabeledField(
                          'Membership No.',
                          _formControllers.membershipNoController.text
                              .toUpperCase(),
                          164.2,
                          // Adaptive.w(13.4),
                        ),
                        pw.SizedBox(width: 61),
                        // pw.SizedBox(width: Adaptive.w(4.6)),
                        _buildLabeledField(
                          'Project.',
                          'Al-Imran-Garden'.toUpperCase(),
                          216,
                          // Adaptive.w(17.3),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 68),
                    _buildLabeledField(
                      'Name.',
                      _formControllers.nameController.text.toUpperCase(),
                      542,
                      // Adaptive.w(43.8),
                    ),

                    pw.SizedBox(height: 16),

                    _buildLabeledField(
                      'S/O,D/O,W/O.',
                      _formControllers.fatherHusbandNameController.text
                          .toUpperCase(),
                      500,
                      // Adaptive.w(40.5),
                    ),

                    pw.SizedBox(height: 16),

                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Column(
                          children: [
                            pw.Row(
                              children: [
                                pw.Align(
                                  alignment:
                                      pw.AlignmentDirectional.bottomStart,
                                  child: pw.Text(
                                    'Permanent Address.',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ),
                                // Container for the address lines
                                pw.Column(
                                  children: _buildAddressLines(
                                    address:
                                        _formControllers.addressController.text
                                            .toUpperCase(),
                                    maxLineLength:
                                        50, // Adjust based on your container width
                                    containerWidth: 460,
                                    underlineWidth: 1.4,
                                    textStyle: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),

                    pw.Row(
                      // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabeledField(
                          'Mobile No.',
                          _formControllers.mobileNoController.text,
                          250,
                          // Adaptive.w(20),
                        ),
                        pw.SizedBox(width: 52),

                        // pw.SizedBox(width: Adaptive.w(4.5)),
                        _buildLabeledField(
                          'Age',
                          _formControllers.ageController.text,
                          193,
                          // Adaptive.w(15.4),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    _buildBoxField(
                      'CNIC / Passport No.',
                      _formControllers.cnicControllers
                          .map((controller) => controller.text)
                          .join(),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '--------------------------------------------------------------',
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildLabeledField(
                      'N.O.K Name.',
                      _formControllers.nokNameController.text.toUpperCase(),
                      504.5,
                      // Adaptive.w(40.8),
                    ),
                    pw.SizedBox(height: 16),

                    _buildLabeledField(
                      'S/O,D/O,W/O.',
                      _formControllers.nokFatherHusbandNameController.text
                          .toUpperCase(),
                      502,
                      // Adaptive.w(40.6),
                    ),

                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Column(
                          children: [
                            pw.Row(
                              children: [
                                pw.Align(
                                  alignment:
                                      pw.AlignmentDirectional.bottomStart,
                                  child: pw.Text(
                                    'Permanent Address.',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ),
                                // Container for the address lines
                                pw.Column(
                                  children: _buildAddressLines(
                                    address:
                                        _formControllers
                                            .nokAddressController
                                            .text
                                            .toUpperCase(),
                                    maxLineLength:
                                        50, // Adjust based on your container width
                                    containerWidth: 460,
                                    underlineWidth: 1.4,
                                    textStyle: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),

                    // pw.SizedBox(height: 2.h),

                    // _buildLabeledField(
                    //   'Permanent Address.',
                    //   _formControllers.addressController.text,
                    //   Adaptive.w(40),
                    // ),
                    // pw.SizedBox(height: 2.h),
                    pw.Row(
                      // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabeledField(
                          'Mobile No.',
                          _formControllers.nokMobileController.text,
                          13 * 15.4,
                        ),
                        pw.SizedBox(width: 13 * 3.5),

                        // pw.SizedBox(width: Adaptive.w(3.7)),
                        _buildLabeledField(
                          'Relation.',
                          _formControllers.relationController.text
                              .toUpperCase(),
                          13 * 17,
                          // Adaptive.w(17.5),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 24),
                    _buildBoxField(
                      'CNIC / Passport No.',
                      _formControllers.nokCnicControllers
                          .map((controller) => controller.text)
                          .join(),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Row(
                      // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabeledField(
                          'Monthly Installment.',
                          _formControllers.monthlyInstallmentController.text,
                          13 * 13.8,
                          // Adaptive.w(14.8),
                        ),
                        pw.SizedBox(width: 13 * 2),
                        // pw.SizedBox(width: 1.8.w),
                        _buildLabeledField(
                          'Half Year Insta.',
                          _formControllers.halfYearInstallmentController.text,
                          13 * 13.1,
                          // Adaptive.w(13.4),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      // mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabeledField(
                          'Development Charges.',
                          _formControllers.developmentChargesController.text,
                          13 * 12.6,
                          // Adaptive.w(13.5),
                        ),
                        pw.SizedBox(width: 13 * 2),
                        // pw.SizedBox(width: 2.w),
                        _buildLabeledField(
                          'Cost of Land.',
                          _formControllers.costOfLandController.text,
                          13 * 13.95,
                          // Adaptive.w(14.1),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 50),
                    // pw.SizedBox(height: 7.5.h),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        // alignment: pw.Alignment.center,
                        width: Adaptive.w(14.5),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Column(
                            children: [
                              pw.Text(
                                '_________________________',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(width: 2.w),
                              pw.Text(
                                'Authorized Sign.',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Get the membership number from the controller
      String membershipNo = _formControllers.membershipNoController.text;

      // Sanitize filename
      String safeName = _formControllers.membershipNoController.text.replaceAll(
        RegExp(r'[^a-zA-Z0-9-_]'),
        '_',
      );

      // Get Downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) throw Exception("Can't access Downloads");

      // Create directory if missing
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Build safe path
      final filePath = '${directory.path}/$safeName.pdf';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'PDF saved to Downloads folder',
      );
      Navigator.pop(context);
    } on PathAccessException catch (_) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Permission denied! Save to Desktop instead.',
      );
    } catch (e) {
      print('PDF Error: $e');
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Failed to save PDF: ${e.toString()}',
      );
    }
  }

  List<pw.Widget> _buildAddressLines({
    required String address,
    required int maxLineLength,
    required double containerWidth,
    required double underlineWidth,
    required pw.TextStyle textStyle,
  }) {
    List<String> words = address.split(' ');
    List<String> lines = [];
    String currentLine = '';

    for (String word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else {
        String potentialLine = '$currentLine $word';
        if (potentialLine.length <= maxLineLength) {
          currentLine = potentialLine;
        } else {
          lines.add(currentLine);
          currentLine = word;
        }
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines
        .map(
          (line) => pw.Container(
            width: containerWidth,
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: underlineWidth)),
            ),
            child: pw.Text(
              line,
              style: textStyle,
              textAlign: pw.TextAlign.center,
            ),
          ),
        )
        .toList();
  }

  pw.Widget _buildLabeledField(String label, String value, double width) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          width: width,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 1.4, color: PdfColors.black),
            ),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 5),
        pw.Expanded(
          child: pw.Row(
            children:
                List.generate(
                  13,
                  (index) => pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 2.6),
                    child: pw.Container(
                      width: 22,
                      height: 22,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 1.4,
                        ),
                      ),
                      child: pw.Text(
                        index < value.length ? value[index] : '',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ).toList(),
          ),
        ),
      ],
    );
  }
}

pw.Widget _buildMultiLineAddressField(String label, String address) {
  final lines = address.split('\n');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 1, color: PdfColors.black),
          ), //Underline
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: lines.map((line) => pw.Text(line)).toList(),
        ),
      ),
    ],
  );
}
