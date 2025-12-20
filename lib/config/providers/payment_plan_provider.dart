import 'package:flutter/material.dart';

enum PaymentPlan { hyInstallment, simplePlan, cash }

class PaymentPlanProvider with ChangeNotifier {
  PaymentPlan? _selectedPlan;

  PaymentPlan? get selectedPlan => _selectedPlan;

  String? get selectedPlanString {
    if (_selectedPlan == null) return null;
    switch (_selectedPlan!) {
      case PaymentPlan.hyInstallment:
        return 'H.Y Installment Plan';
      case PaymentPlan.simplePlan:
        return 'Simple Plan';
      case PaymentPlan.cash:
        return 'Cash';
    }
  }

  void setSelectedPlan(PaymentPlan? plan) {
    if (_selectedPlan == plan) return; // Prevent unnecessary rebuilds
    _selectedPlan = plan;
    notifyListeners();
  }

  void clearSelection() {
    setSelectedPlan(null);
  }

  bool get hasSelection => _selectedPlan != null;

  // Add type-safe conversion for database operations
  static PaymentPlan? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'h.y installment plan':
        return PaymentPlan.hyInstallment;
      case 'simple plan':
        return PaymentPlan.simplePlan;
      case 'cash':
        return PaymentPlan.cash;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _selectedPlan = null;
    super.dispose();
  }
}