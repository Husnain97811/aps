// discount_fields_provider.dart
import 'package:flutter/foundation.dart';

class DiscountFieldsProvider with ChangeNotifier {
  bool _showOfferFields = false;
  String _discount = '';
  String _receivedAmount = '';
  String _offerDiscountAmount = '';
  bool _specialOffer = false;

  bool get showOfferFields => _showOfferFields;
  String get discount => _discount;
  String get receivedAmount => _receivedAmount;
  String get offerDiscountAmount => _offerDiscountAmount;
  bool get specialOffer => _specialOffer;

  void toggleOfferFields(bool value) {
    _showOfferFields = value;
    _specialOffer = value; // Set special offer based on checkbox
    notifyListeners();
  }

  void setDiscount(String value) {
    _discount = _validateAmount(value);
    notifyListeners();
  }

  void setReceivedAmount(String value) {
    _receivedAmount = _validateAmount(value);
    notifyListeners();
  }

  void setOfferDiscountAmount(String value) {
    _offerDiscountAmount = _validateAmount(value);
    notifyListeners();
  }

  void setSpecialOffer(bool value) {
    _specialOffer = value;
    notifyListeners();
  }

  String _validateAmount(String value) {
    // Remove any leading zeros
    if (value == '0' || value == '00' || value == '') {
      return '';
    }

    // Try to parse as double to remove unnecessary zeros
    try {
      final numVal = double.parse(value);
      if (numVal == 0) return '';
      return numVal.toString();
    } catch (e) {
      return value;
    }
  }

  String getAmountForDisplay() {
    if (_showOfferFields && _offerDiscountAmount.isNotEmpty) {
      return _offerDiscountAmount;
    } else if (_receivedAmount.isNotEmpty) {
      return _receivedAmount;
    }
    return '';
  }

  String getDiscountForDisplay() {
    return _discount.isNotEmpty ? _discount : '';
  }

  String getOfferDiscountForDisplay() {
    return _offerDiscountAmount.isNotEmpty ? _offerDiscountAmount : '';
  }

  bool get hasDiscount => _discount.isNotEmpty;
  bool get hasOfferDiscount => _offerDiscountAmount.isNotEmpty;

  void clearAll() {
    _discount = '';
    _receivedAmount = '';
    _offerDiscountAmount = '';
    _specialOffer = false;
    _showOfferFields = false;
    notifyListeners();
  }
}
