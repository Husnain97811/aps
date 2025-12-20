import 'package:flutter/material.dart';

class FormControllers {
  //Membership form controllers
  TextEditingController formNoController = TextEditingController();
  TextEditingController dlNoController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController membershipNoController = TextEditingController();
  TextEditingController projectController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController fatherHusbandNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController mobileNoController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  List<TextEditingController> cnicControllers = List.generate(
    13,
    (_) => TextEditingController(),
  );
  List<FocusNode> cnicFocusNodes = List.generate(13, (_) => FocusNode());
  TextEditingController nokNameController = TextEditingController();
  TextEditingController nokFatherHusbandNameController =
      TextEditingController();
  TextEditingController nokAddressController = TextEditingController();
  TextEditingController nokMobileController = TextEditingController();
  TextEditingController relationController = TextEditingController();
  List<TextEditingController> nokCnicControllers = List.generate(
    13,
    (_) => TextEditingController(),
  );
  List<FocusNode> nokCnicFocusNodes = List.generate(13, (_) => FocusNode());
  TextEditingController halfYearInstallmentController = TextEditingController();
  TextEditingController monthlyInstallmentController = TextEditingController();
  TextEditingController developmentChargesController = TextEditingController();
  TextEditingController costOfLandController = TextEditingController();
  TextEditingController discountController = TextEditingController();

  //Installment Receipt form controllers
  TextEditingController receiptNoController = TextEditingController();
  TextEditingController installmentNoController = TextEditingController();
  TextEditingController receivedAmountController = TextEditingController();
  TextEditingController amountInWordsController = TextEditingController();
  TextEditingController modeOfPaymentController = TextEditingController();
  TextEditingController offerReceivedAmountController = TextEditingController();
  TextEditingController offerDiscountAmountController = TextEditingController();
  TextEditingController authorizedSignatureController = TextEditingController();
  TextEditingController plotNoController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController plotSizeController = TextEditingController();
  TextEditingController specialTypeController = TextEditingController();
  TextEditingController isSpecialController = TextEditingController();

  TextEditingController specialCategoryController = TextEditingController();
  TextEditingController additionalChargesController = TextEditingController();
  TextEditingController downPaymentController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  void dispose() {
    formNoController.dispose();
    dlNoController.dispose();
    dateController.dispose();
    membershipNoController.dispose();
    projectController.dispose();
    nameController.dispose();
    fatherHusbandNameController.dispose();
    addressController.dispose();
    mobileNoController.dispose();
    ageController.dispose();
    for (var controller in cnicControllers) {
      controller.dispose();
    }
    for (var node in cnicFocusNodes) {
      node.dispose();
    }
    nokNameController.dispose();
    nokFatherHusbandNameController.dispose();
    nokAddressController.dispose();
    nokMobileController.dispose();
    relationController.dispose();
    for (var controller in nokCnicControllers) {
      controller.dispose();
    }
    for (var node in nokCnicFocusNodes) {
      node.dispose();
    }
    halfYearInstallmentController.dispose();
    monthlyInstallmentController.dispose();
    developmentChargesController.dispose();
    costOfLandController.dispose();
    discountController.dispose();

    receiptNoController.dispose();
    installmentNoController.dispose();
    receivedAmountController.dispose();
    amountInWordsController.dispose();
    modeOfPaymentController.dispose();
    offerReceivedAmountController.dispose();
    offerDiscountAmountController.dispose();
    authorizedSignatureController.dispose();
    plotNoController.dispose();
    categoryController.dispose();
    plotSizeController.dispose();
    specialTypeController.dispose();
    isSpecialController.dispose();
    specialCategoryController.dispose();
    additionalChargesController.dispose();
    downPaymentController.dispose();
  }
}
