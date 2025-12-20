import 'package:flutter/material.dart';

class LateInstallmentsOfferProvider extends ChangeNotifier {
  bool _isLateInstallmentsOffer = false;

  bool get isLateInstallmentsOffer => _isLateInstallmentsOffer;

  void toggleLateInstallmentsOffer() {
    _isLateInstallmentsOffer = !_isLateInstallmentsOffer;
    notifyListeners();
  }

  void setLateInstallmentsOffer(bool value) {
    _isLateInstallmentsOffer = value;
    notifyListeners();
  }
}
