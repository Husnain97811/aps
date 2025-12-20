// providers/installment_receipt_provider.dart
import 'package:flutter/foundation.dart';

class InstallmentReceiptProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isSavingPdf = false;

  bool get isLoading => _isLoading;
  bool get isSavingPdf => _isSavingPdf;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSavingPdf(bool value) {
    _isSavingPdf = value;
    notifyListeners();
  }
}