// Add to your provider file
import 'package:flutter/material.dart';

enum PaymentDescription {
  cash('Cash'),
  installment('Simple Installment'),
  hyInstallment('HY Installment'),
  developmentCharges('Development Charges');

  final String displayName;
  const PaymentDescription(this.displayName);

  @override
  String toString() => displayName;

  // Add this to convert string back to enum
  static PaymentDescription? fromString(String value) {
    return PaymentDescription.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => PaymentDescription.installment,
    );
  }
}

class PaymentDescriptionProvider with ChangeNotifier {
  PaymentDescription _selectedDescription = PaymentDescription.installment;

  PaymentDescription get selectedDescription => _selectedDescription;

  void setDescription(PaymentDescription description) {
    _selectedDescription = description;
    notifyListeners();
  }

  // Add this to handle string values
  void setDescriptionFromString(String value) {
    final desc = PaymentDescription.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => PaymentDescription.installment,
    );
    _selectedDescription = desc;
    notifyListeners();
  }
}

// providers/special_offer_provider.dart

class SpecialOfferProvider with ChangeNotifier {
  bool _isSpecialOffer = false;

  bool get isSpecialOffer => _isSpecialOffer;

  void setSpecialOffer(bool value) {
    _isSpecialOffer = value;
    notifyListeners();
  }

  void toggleSpecialOffer() {
    _isSpecialOffer = !_isSpecialOffer;
    notifyListeners();
  }
}
