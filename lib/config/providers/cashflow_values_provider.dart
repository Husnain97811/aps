import 'package:flutter/material.dart';

class ValueVisibilityProvider with ChangeNotifier {
  bool _showIncome = false;
  bool _showExpenses = false;
  bool _showNetCash = false;

  bool get showIncome => _showIncome;
  bool get showExpenses => _showExpenses;
  bool get showNetCash => _showNetCash;

  void toggleIncome() {
    _showIncome = !_showIncome;
    notifyListeners();
  }

  void toggleExpenses() {
    _showExpenses = !_showExpenses;
    notifyListeners();
  }

  void toggleNetCash() {
    _showNetCash = !_showNetCash;
    notifyListeners();
  }
}
