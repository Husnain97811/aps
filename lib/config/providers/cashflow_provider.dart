import 'package:flutter/material.dart';

class CashFlowProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cashInEntries = [];
  final List<Map<String, dynamic>> _cashOutEntries = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get cashInEntries => _cashInEntries;
  List<Map<String, dynamic>> get cashOutEntries => _cashOutEntries;
  bool get isLoading => _isLoading;

  void addCashIn(Map<String, dynamic> entry) {
    _cashInEntries.add(entry);
    notifyListeners();
  }

  void addCashOut(Map<String, dynamic> entry) {
    _cashOutEntries.add(entry);
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
